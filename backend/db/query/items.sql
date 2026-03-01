-- name: CreateUser :one
INSERT INTO users (username, password, created_by) 
VALUES ($1, $2, $3) RETURNING *;

-- name: CreateTerm :one
INSERT INTO terms (term, created_by) 
VALUES ($1, $2) RETURNING *;

-- name: CreateWord :one
INSERT INTO words (word, created_by) 
VALUES ($1, $2) RETURNING *;

-- name: LinkTermAndWord :exec
INSERT INTO terms_words (term_id, word_id, created_by)
VALUES ($1, $2, $3);

-- name: GetTermWithWords :one
-- This uses JSON_AGG to return the "related_words" as a single field!
SELECT 
    t.id, 
    t.term, 
    t.created_at,
    json_agg(w.word) FILTER (WHERE w.word IS NOT NULL) AS related_words
FROM terms t
LEFT JOIN terms_words tw ON t.id = tw.term_id
LEFT JOIN words w ON tw.word_id = w.id
WHERE t.id = $1
GROUP BY t.id;
