---
VAR:
  INT:  \d+
  DATE: (\d{4})-?(\d{2})-?(\d{2})


ACTION:
  # sample. try to access:
  #   http://<installed>/hello/1234
  #   http://<installed>/date/2009-12-04
  - name: default
    rule:
      - path_re: ^ hello/ ($INT) /?$
        param:   [ int ]
      - path_re: ^ date/ ${DATE} /?$
        param:   [ yyyy, mm, dd ]

  - name: default
    rule:
      - path_re: ^ .* $
