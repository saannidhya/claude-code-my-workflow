suppressPackageStartupMessages({library(duckdb); library(DBI)})
con <- dbConnect(duckdb::duckdb())
g <- "data/corelogic_extracts/by_state/ot/state=RI/year=2019/*.parquet"
q1 <- sprintf("SELECT typeof(fips_code) tf, typeof(buyer_mailing_zip_code) tmz,
               typeof(deed_situs_zip_code_static) tsz,
               fips_code, buyer_mailing_zip_code, deed_situs_zip_code_static
               FROM read_parquet('%s')
               WHERE buyer_mailing_zip_code IS NOT NULL LIMIT 8", g)
print(dbGetQuery(con, q1))
q2 <- sprintf("SELECT min(length(CAST(buyer_mailing_zip_code AS VARCHAR))) mn,
               max(length(CAST(buyer_mailing_zip_code AS VARCHAR))) mx,
               min(length(CAST(deed_situs_zip_code_static AS VARCHAR))) smn,
               max(length(CAST(deed_situs_zip_code_static AS VARCHAR))) smx
               FROM read_parquet('%s') WHERE buyer_mailing_zip_code IS NOT NULL", g)
print(dbGetQuery(con, q2))
# check a non-leading-zero state too
g2 <- "data/corelogic_extracts/by_state/ot/state=CA/year=2019/*.parquet"
q3 <- sprintf("SELECT typeof(fips_code) tf, typeof(buyer_mailing_zip_code) tmz,
               fips_code, buyer_mailing_zip_code FROM read_parquet('%s') LIMIT 5", g2)
print(dbGetQuery(con, q3))
dbDisconnect(con, shutdown = TRUE)
