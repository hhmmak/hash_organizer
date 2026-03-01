-- 1. USERS TABLE
CREATE TABLE users (
    id bigserial PRIMARY KEY,
    username varchar NOT NULL UNIQUE,
    password varchar NOT NULL, -- Store the HASH, not plain text
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    -- created_by is nullable here because the first admin has no creator
    created_by bigint REFERENCES users(id)
);

-- 2. TERMS TABLE
CREATE TABLE terms (
    id bigserial PRIMARY KEY,
    term varchar NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by bigint NOT NULL REFERENCES users(id)
);

-- 3. WORDS TABLE
CREATE TABLE words (
    id bigserial PRIMARY KEY,
    word varchar NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by bigint NOT NULL REFERENCES users(id)
);

-- 4. TERMS_WORDS (Many-to-Many Junction)
CREATE TABLE terms_words (
    term_id bigint NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
    word_id bigint NOT NULL REFERENCES words(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by bigint NOT NULL REFERENCES users(id),
    PRIMARY KEY (term_id, word_id) -- Prevents duplicate links
);

-- Indexes for performance
CREATE INDEX ON terms (term);
CREATE INDEX ON words (word);
