<IfModule mod_rewrite.c>
RewriteEngine on
RewriteBase   <?= $request_path ?>/

RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule .* index.cgi [L]
</IfModule>

<Files ~ "\.(?:pl|pm|yml|mt|t)$">
Order deny,allow
deny from all
</Files>

<Files ~ "^\.">
Order deny,allow
deny from all
</Files>
