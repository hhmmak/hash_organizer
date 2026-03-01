package main

import (
	"context"
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/yourusername/backend/db" // Import your generated sqlc package
)

func main() {
    // 1. Connect to Neon
	conn, err := sql.Open("pgx", "your_neon_connection_string")
	if err != nil {
		panic(err)
	}

    // 2. Create the Queries instance
	queries := db.New(conn)

	r := gin.Default()

    // POST /terms - Create a term and link existing words
	r.POST("/terms", func(c *gin.Context) {
		var req struct {
			Term      string   `json:"term"`
			WordIDs   []int64  `json:"word_ids"` // User sends IDs of words to link
			UserID    int64    `json:"user_id"`  // In real app, get this from Auth Token
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": err.Error()})
			return
		}

		ctx := context.Background()

        // A. Create the Term
        // We use sql.NullInt64 for created_by since it's nullable in User, 
        // but required in Terms. Adjust schema if needed. 
        // Here we assume UserID is valid.
		newTerm, err := queries.CreateTerm(ctx, db.CreateTermParams{
			Term:      req.Term,
			CreatedBy: req.UserID,
		})
		if err != nil {
			c.JSON(500, gin.H{"error": "Failed to create term"})
			return
		}

        // B. Link the Words (Loop through IDs)
		for _, wordID := range req.WordIDs {
			err := queries.LinkTermAndWord(ctx, db.LinkTermAndWordParams{
				TermID:    newTerm.ID,
				WordID:    wordID,
				CreatedBy: req.UserID,
			})
			if err != nil {
                // In production, you would rollback a transaction here!
				c.JSON(500, gin.H{"error": "Failed to link word"})
				return
			}
		}

		c.JSON(201, newTerm)
	})

    // GET /terms/:id - Fetch Term AND its words
    r.GET("/terms/:id", func(c *gin.Context) {
        var uri struct { ID int64 `uri:"id" binding:"required"` }
        if err := c.ShouldBindUri(&uri); err != nil {
            c.JSON(400, gin.H{"error": err.Error()})
            return
        }

        // Uses the special Join query we wrote!
        result, err := queries.GetTermWithWords(context.Background(), uri.ID)
        if err != nil {
            c.JSON(404, gin.H{"error": "Term not found"})
            return
        }

        c.JSON(200, result) 
        // Response will look like: 
        // { "id": 1, "term": "Golang", "related_words": ["fast", "compiled", "google"] }
    })

	r.Run(":10000")
}
