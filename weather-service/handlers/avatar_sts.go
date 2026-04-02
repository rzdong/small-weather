package handlers

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	sts "github.com/tencentyun/qcloud-cos-sts-sdk/go"
)

func GetAvatarUploadSTS(c *gin.Context) {
	bucket := os.Getenv("COS_BUCKET")
	region := os.Getenv("COS_REGION")
	appID := os.Getenv("COS_APPID")
	basePrefix := os.Getenv("COS_BASE_PREFIX")
	secretID := os.Getenv("COS_SECRET_ID")
	secretKey := os.Getenv("COS_SECRET_KEY")

	if bucket == "" || region == "" || appID == "" || basePrefix == "" || secretID == "" || secretKey == "" {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "COS temporary credential service is not fully configured",
		})
		return
	}

	userID := c.GetInt("userID")
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Unauthorized"})
		return
	}

	prefix := fmt.Sprintf("%s/%d/*", basePrefix, userID)
	resource := fmt.Sprintf(
		"qcs::cos:%s:uid/%s:%s/%s",
		region,
		appID,
		bucket,
		prefix,
	)

	client := sts.NewClient(secretID, secretKey, &http.Client{
		Timeout: 15 * time.Second,
	})

	result, err := client.GetCredential(&sts.CredentialOptions{
		Region:          region,
		DurationSeconds: 1800,
		Policy: &sts.CredentialPolicy{
			Statement: []sts.CredentialPolicyStatement{
				{
					Action: []string{
						"name/cos:PutObject",
						"name/cos:PostObject",
						"name/cos:InitiateMultipartUpload",
						"name/cos:ListMultipartUploads",
						"name/cos:ListParts",
						"name/cos:UploadPart",
						"name/cos:CompleteMultipartUpload",
					},
					Effect: "allow",
					Resource: []string{
						resource,
					},
				},
			},
		},
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": fmt.Sprintf("Failed to create temporary credentials: %v", err),
		})
		return
	}

	if result == nil || result.Credentials == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create temporary credentials: empty credential result",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"credentials": gin.H{
				"tmpSecretId":  result.Credentials.TmpSecretID,
				"tmpSecretKey": result.Credentials.TmpSecretKey,
				"sessionToken": result.Credentials.SessionToken,
			},
			"startTime":   result.StartTime,
			"expiredTime": result.ExpiredTime,
			"bucket":      bucket,
			"region":      region,
			"prefix":      fmt.Sprintf("%s/%d/", basePrefix, userID),
		},
	})
}
