• 
• RHEL/CentOS: sudo dnf install postgresql-devel libzip-devel

example 
-- Extract 'docs/readme.txt' from a stored zip archive and convert to UTF-8 text
SELECT convert_from(unzip_bytea(archive_blob, 'docs/readme.txt'), 'UTF8')
FROM my_archives
WHERE id = 1;
