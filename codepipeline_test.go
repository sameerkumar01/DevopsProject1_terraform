package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/codepipeline"

	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAwsCodePipelineProduction(t *testing.T) {
	t.Parallel()

	uniqueId := strings.ToLower(random.UniqueId())
	projectName := fmt.Sprintf("test-prod-app-%s", uniqueId)
	awsRegion := "ap-south-1"

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"project_name":      projectName,
			"aws_region":        awsRegion,
			"github_repo_owner": "ameet56",
			"github_repo_name":  "terraform-demo",
			"github_branch":     "main",
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	websiteURL := terraform.Output(t, terraformOptions, "website_url")
	connectionArn := terraform.Output(t, terraformOptions, "codestar_connection_arn")
	pipelineName := terraform.Output(t, terraformOptions, "codepipeline_name")

	t.Logf("PAUSING FOR 1 MINUTE to allow for manual CodeStar connection approval.")
	t.Logf("Please go to the AWS Console and approve the connection with ARN: %s", connectionArn)
	time.Sleep(1 * time.Minute)

	// Start pipeline execution
	err := startPipelineExecution(t, awsRegion, pipelineName)
	assert.NoError(t, err)
	t.Logf("Manually started pipeline %s. Waiting for deployment to complete...", pipelineName)

	// FIX: Increased the wait time from 5 minutes to 15 minutes (900 seconds)
	// to allow the slow, zero-downtime rolling deployment to complete.
	t.Logf("Waiting for 18 minutes for the deployment to finish...")
	time.Sleep(900 * time.Second)

	// Optional: Log raw HTTP output for debugging
	status, body := http_helper.HttpGet(t, websiteURL, nil)
	t.Logf("HTTP Status: %d", status)
	t.Logf("HTTP Body: %s", body)

	// Validate the website is accessible via the Load Balancer
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		websiteURL,
		nil,
		30,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == 200
		},
	)

	t.Logf("Successfully validated that the website is live.")
}

func startPipelineExecution(t *testing.T, awsRegion string, pipelineName string) error {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	if err != nil {
		return err
	}
	svc := codepipeline.New(sess)

	_, err = svc.StartPipelineExecution(&codepipeline.StartPipelineExecutionInput{
		Name: aws.String(pipelineName),
	})
	return err
}
