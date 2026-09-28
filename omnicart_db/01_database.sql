-- ========================================================================
-- Project: OmniCart Marketplace Database
-- Author: Database Architect
-- Date: 2026-09-27
-- Description: This script creates the OmniCartDB database, setting the 
--              appropriate character set and collation for internationalization.
-- ========================================================================

DROP DATABASE IF EXISTS OmniCartDB;
CREATE DATABASE OmniCartDB 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE OmniCartDB;
