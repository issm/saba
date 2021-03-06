---
LOCATION:
  PROTOCOL:  <?= $protocol;     ?>
  DOMAIN:    <?= $server_name;  ?>
  SUBDOMAIN: <?= $subdomain;    ?>
  PATH:      <?= $request_path; ?>

PAGE:
  COMMON_CSS: [_base, _layout, _additional]
  COMMON_JS:  [_base, _additional]

DSI:
  DBI:  0
  YAML: 1

DB:
  TYPE:   mysql
  NAME:   dbname
  HOST:   localhost
  USER:   user
  PASSWD: password
  TABLE_PREFIX: pre_

CACHE:
  ENABLED:   <?= $cache_enabled; ?>
  NAMESPACE: <?= $subdomain; ?><?= $server_name; ?>
  EXPIRES:   600
  ROOT:

COOKIE:
  EXPIRES: +14d
  DOMAIN:  
  PATH:
  SECURE:  0

MAIL:
  SERVER_SMTP: localhost:587
  ADDRESS:
    FROM: noreply@example.com
    CC:
  SIGNATURE: |
    --
    your email signature.


CONTENT_TYPE_DEFAULT: text/html; charset=utf-8
