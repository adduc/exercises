package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type Event struct {
	EntityId  string
	Timestamp string
}

// posts dummy data to a dynamodb table
func main() {

	ctx := context.Background()

	cfg, err := NewAwsConfig(ctx)
	if err != nil {
		panic("failed to load configuration")
	}

	client := NewDynamoDbClient(cfg)

	dummyEvent := Event{
		EntityId:  "1234",
		Timestamp: "2023-10-10T10:00:00Z",
	}

	err = SaveEventToDynamoDB(client, dummyEvent)
	if err != nil {
		fmt.Println("failed to save event", err)
		panic("failed to save event")
	}
}

func NewAwsConfig(ctx context.Context) (aws.Config, error) {
	return config.LoadDefaultConfig(ctx)
}

func NewDynamoDbClient(cfg aws.Config) *dynamodb.Client {
	return dynamodb.NewFromConfig(cfg)
}

func SaveEventToDynamoDB(client *dynamodb.Client, event Event) error {

	tableName := "example-table" // replace with your table name

	_, err := client.PutItem(context.TODO(), &dynamodb.PutItemInput{
		TableName: &tableName,
		Item: map[string]types.AttributeValue{
			"EntityId":  &types.AttributeValueMemberS{Value: event.EntityId},
			"Timestamp": &types.AttributeValueMemberS{Value: event.Timestamp},
		},
	})

	if err != nil {
		return err
	}

	return nil
}
