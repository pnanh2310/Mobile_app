-- ========================================
-- PCM Database Creation Script - PostgreSQL
-- MSSV: 1772050056
-- ========================================

-- Create database (run this separately first)
-- CREATE DATABASE pcm_056_db;
-- Connect to database

-- ========================================
-- DROP existing tables (if any)
-- ========================================

DROP TABLE IF EXISTS "056_Notifications" CASCADE;
DROP TABLE IF EXISTS "056_Matches" CASCADE;
DROP TABLE IF EXISTS "056_TournamentParticipants" CASCADE;
DROP TABLE IF EXISTS "056_Tournaments" CASCADE;
DROP TABLE IF EXISTS "056_Bookings" CASCADE;
DROP TABLE IF EXISTS "056_Courts" CASCADE;
DROP TABLE IF EXISTS "056_WalletTransactions" CASCADE;
DROP TABLE IF EXISTS "056_News" CASCADE;
DROP TABLE IF EXISTS "056_Members" CASCADE;

-- Drop Identity tables
DROP TABLE IF EXISTS "AspNetUserTokens" CASCADE;
DROP TABLE IF EXISTS "AspNetUserRoles" CASCADE;
DROP TABLE IF EXISTS "AspNetUserLogins" CASCADE;
DROP TABLE IF EXISTS "AspNetUserClaims" CASCADE;
DROP TABLE IF EXISTS "AspNetRoleClaims" CASCADE;
DROP TABLE IF EXISTS "AspNetRoles" CASCADE;
DROP TABLE IF EXISTS "AspNetUsers" CASCADE;

-- ========================================
-- Create Identity Tables
-- ========================================

CREATE TABLE "AspNetRoles" (
    "Id" TEXT NOT NULL PRIMARY KEY,
    "Name" VARCHAR(256),
    "NormalizedName" VARCHAR(256),
    "ConcurrencyStamp" TEXT
);

CREATE TABLE "AspNetUsers" (
    "Id" TEXT NOT NULL PRIMARY KEY,
    "UserName" VARCHAR(256),
    "NormalizedUserName" VARCHAR(256),
    "Email" VARCHAR(256),
    "NormalizedEmail" VARCHAR(256),
    "EmailConfirmed" BOOLEAN NOT NULL,
    "PasswordHash" TEXT,
    "SecurityStamp" TEXT,
    "ConcurrencyStamp" TEXT,
    "PhoneNumber" TEXT,
    "PhoneNumberConfirmed" BOOLEAN NOT NULL,
    "TwoFactorEnabled" BOOLEAN NOT NULL,
    "LockoutEnd" TIMESTAMPTZ,
    "LockoutEnabled" BOOLEAN NOT NULL,
    "AccessFailedCount" INTEGER NOT NULL
);

CREATE TABLE "AspNetUserRoles" (
    "UserId" TEXT NOT NULL,
    "RoleId" TEXT NOT NULL,
    PRIMARY KEY ("UserId", "RoleId"),
    FOREIGN KEY ("UserId") REFERENCES "AspNetUsers"("Id") ON DELETE CASCADE,
    FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles"("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserClaims" (
    "Id" SERIAL PRIMARY KEY,
    "UserId" TEXT NOT NULL,
    "ClaimType" TEXT,
    "ClaimValue" TEXT,
    FOREIGN KEY ("UserId") REFERENCES "AspNetUsers"("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserLogins" (
    "LoginProvider" TEXT NOT NULL,
    "ProviderKey" TEXT NOT NULL,
    "ProviderDisplayName" TEXT,
    "UserId" TEXT NOT NULL,
    PRIMARY KEY ("LoginProvider", "ProviderKey"),
    FOREIGN KEY ("UserId") REFERENCES "AspNetUsers"("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserTokens" (
    "UserId" TEXT NOT NULL,
    "LoginProvider" TEXT NOT NULL,
    "Name" TEXT NOT NULL,
    "Value" TEXT,
    PRIMARY KEY ("UserId", "LoginProvider", "Name"),
    FOREIGN KEY ("UserId") REFERENCES "AspNetUsers"("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetRoleClaims" (
    "Id" SERIAL PRIMARY KEY,
    "RoleId" TEXT NOT NULL,
    "ClaimType" TEXT,
    "ClaimValue" TEXT,
    FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles"("Id") ON DELETE CASCADE
);

-- ========================================
-- Create Application Tables
-- ========================================

-- Members Table
CREATE TABLE "056_Members" (
    "Id" SERIAL PRIMARY KEY,
    "IdentityUserId" TEXT NOT NULL,
    "FullName" VARCHAR(100) NOT NULL,
    "DateOfBirth" TIMESTAMPTZ NOT NULL,
    "Gender" INTEGER NOT NULL,
    "Phone" VARCHAR(20),
    "WalletBalance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "Tier" INTEGER NOT NULL DEFAULT 0,
    "RankLevel" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "TotalSpent" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "AvatarUrl" VARCHAR(500),
    "JoinDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("IdentityUserId") REFERENCES "AspNetUsers"("Id") ON DELETE CASCADE
);

-- Wallet Transactions Table
CREATE TABLE "056_WalletTransactions" (
    "Id" SERIAL PRIMARY KEY,
    "MemberId" INTEGER NOT NULL,
    "Amount" DOUBLE PRECISION NOT NULL,
    "Type" INTEGER NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "Description" VARCHAR(500),
    "ProofImageUrl" VARCHAR(500),
    "CreatedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ProcessedDate" TIMESTAMPTZ,
    "ProcessedBy" TEXT,
    FOREIGN KEY ("MemberId") REFERENCES "056_Members"("Id") ON DELETE CASCADE
);

-- Courts Table  
CREATE TABLE "056_Courts" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL,
    "Description" VARCHAR(500),
    "IsIndoor" BOOLEAN NOT NULL DEFAULT FALSE,
    "PricePerHour" DOUBLE PRECISION NOT NULL,
    "IsAvailable" BOOLEAN NOT NULL DEFAULT TRUE
);

-- Bookings Table
CREATE TABLE "056_Bookings" (
    "Id" SERIAL PRIMARY KEY,
    "MemberId" INTEGER NOT NULL,
    "CourtId" INTEGER NOT NULL,
    "StartTime" TIMESTAMPTZ NOT NULL,
    "EndTime" TIMESTAMPTZ NOT NULL,
    "TotalPrice" DOUBLE PRECISION NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "IsRecurring" BOOLEAN NOT NULL DEFAULT FALSE,
    "RecurringUntil" TIMESTAMPTZ,
    "CreatedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("MemberId") REFERENCES "056_Members"("Id") ON DELETE CASCADE,
    FOREIGN KEY ("CourtId") REFERENCES "056_Courts"("Id") ON DELETE RESTRICT
);

-- Tournaments Table
CREATE TABLE "056_Tournaments" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL,
    "Description" VARCHAR(500),
    "StartDate" TIMESTAMPTZ NOT NULL,
    "EndDate" TIMESTAMPTZ NOT NULL,
    "Format" INTEGER NOT NULL,
    "EntryFee" DOUBLE PRECISION NOT NULL,
    "PrizePool" DOUBLE PRECISION NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "MaxParticipants" INTEGER NOT NULL,
    "CurrentParticipants" INTEGER NOT NULL DEFAULT 0
);

-- Tournament Participants Table
CREATE TABLE "056_TournamentParticipants" (
    "Id" SERIAL PRIMARY KEY,
    "TournamentId" INTEGER NOT NULL,
    "MemberId" INTEGER NOT NULL,
    "PartnerId" INTEGER,
    "TeamName" VARCHAR(100),
    "Seed" INTEGER,
    "IsPaid" BOOLEAN NOT NULL DEFAULT FALSE,
    "JoinedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("TournamentId") REFERENCES "056_Tournaments"("Id") ON DELETE CASCADE,
    FOREIGN KEY ("MemberId") REFERENCES "056_Members"("Id") ON DELETE CASCADE,
    FOREIGN KEY ("PartnerId") REFERENCES "056_Members"("Id") ON DELETE SET NULL
);

-- Matches Table
CREATE TABLE "056_Matches" (
    "Id" SERIAL PRIMARY KEY,
    "TournamentId" INTEGER,
    "Team1Player1Id" INTEGER NOT NULL,
    "Team1Player2Id" INTEGER,
    "Team2Player1Id" INTEGER NOT NULL,
    "Team2Player2Id" INTEGER,
    "StartTime" TIMESTAMPTZ NOT NULL,
    "CourtId" INTEGER,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "Team1Set1Score" INTEGER,
    "Team1Set2Score" INTEGER,
    "Team1Set3Score" INTEGER,
    "Team2Set1Score" INTEGER,
    "Team2Set2Score" INTEGER,
    "Team2Set3Score" INTEGER,
    "WinningSide" INTEGER,
    "Round" VARCHAR(50),
    "BracketPosition" INTEGER,
    FOREIGN KEY ("TournamentId") REFERENCES "056_Tournaments"("Id") ON DELETE SET NULL,
    FOREIGN KEY ("Team1Player1Id") REFERENCES "056_Members"("Id") ON DELETE RESTRICT,
    FOREIGN KEY ("Team1Player2Id") REFERENCES "056_Members"("Id") ON DELETE SET NULL,
    FOREIGN KEY ("Team2Player1Id") REFERENCES "056_Members"("Id") ON DELETE RESTRICT,
    FOREIGN KEY ("Team2Player2Id") REFERENCES "056_Members"("Id") ON DELETE SET NULL,
    FOREIGN KEY ("CourtId") REFERENCES "056_Courts"("Id") ON DELETE SET NULL
);

-- News Table
CREATE TABLE "056_News" (
    "Id" SERIAL PRIMARY KEY,
    "Title" VARCHAR(200) NOT NULL,
    "Content" TEXT NOT NULL,
    "ImageUrl" VARCHAR(500),
    "AuthorId" TEXT NOT NULL,
    "IsPinned" BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("AuthorId") REFERENCES "AspNetUsers"("Id") ON DELETE RESTRICT
);

-- Notifications Table
CREATE TABLE "056_Notifications" (
    "Id" SERIAL PRIMARY KEY,
    "MemberId" INTEGER NOT NULL,
    "Title" VARCHAR(200) NOT NULL,
    "Message" TEXT NOT NULL,
    "Type" INTEGER NOT NULL,
    "RelatedId" INTEGER,
    "IsRead" BOOLEAN NOT NULL DEFAULT FALSE,
    "DeepLink" VARCHAR(200),
    "CreatedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("MemberId") REFERENCES "056_Members"("Id") ON DELETE CASCADE
);

-- ========================================
-- Create Indexes
-- ========================================

CREATE INDEX "IX_056_Members_IdentityUserId" ON "056_Members"("IdentityUserId");
CREATE INDEX "IX_056_WalletTransactions_MemberId" ON "056_WalletTransactions"("MemberId");
CREATE INDEX "IX_056_Bookings_MemberId" ON "056_Bookings"("MemberId");
CREATE INDEX "IX_056_Bookings_CourtId" ON "056_Bookings"("CourtId");
CREATE INDEX "IX_056_Bookings_StartTime" ON "056_Bookings"("StartTime");
CREATE INDEX "IX_056_TournamentParticipants_TournamentId" ON "056_TournamentParticipants"("TournamentId");
CREATE INDEX "IX_056_TournamentParticipants_MemberId" ON "056_TournamentParticipants"("MemberId");
CREATE INDEX "IX_056_Matches_TournamentId" ON "056_Matches"("TournamentId");
CREATE INDEX "IX_056_Notifications_MemberId" ON "056_Notifications"("MemberId");
CREATE INDEX "IX_AspNetUserRoles_RoleId" ON "AspNetUserRoles"("RoleId");

-- ========================================
-- Seed Data will be in Part 2
-- ========================================

COMMIT;
