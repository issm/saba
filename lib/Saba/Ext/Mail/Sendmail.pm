package Saba::Ext::Mail::Sendmail;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

use Mail::Sendmail;
use Encode qw/encode decode is_utf8/;
use Text::MicroTemplate::Extended;
use Saba::Config;
use Saba::ClassBase qw/:base :debug/;


my $_conf = {};


#
#  コンストラクタ
#
#  @param   ?smtp           scalar   SMTP
#  @param   ?from           scalar   送信者のメールアドレス
#  @param   ?to             scalar   受信者のメールアドレス
#                           arrayref
#  @param   ?cc             scalar
#  @param   ?bcc            scalar
#  @param   ?reply_to       scalar   返信先のメールアドレス
#  @param   ?subject        scalar   件名
#  @param   ?template_path  scalar   テンプレートのインクルードパス
#
__PACKAGE__->mk_accessors qw/smtp
                             from
                             to
                             cc
                             bcc
                             reply_to
                             subject
                             template_path
                            /;

#
#  初期化
#
sub init {
  my $self = shift;
  $_conf = Saba::Config->new->get;
  $self;
}


#
#  メールを送信する
#
#  @param    from      scalar   送信者のメールアドレス
#  @param    to        scalar   受信者のメールアドレス
#                      arrayref
#  @param   ?cc        scalar
#  @param   ?bcc       scalar
#  @param   ?reply_to  scalar   返信先のメールアドレス
#  @param    subject   scalar   件名
#  @param   -body      scalar   本文
#  @param   -template  hashref  テンプレート指定
#              -name   scalar   テンプレート名 （.tpl を含まない）
#              -file   scalar   テンプレートファイル（.tpl を含む）
#               var    hashref  テンプレート変数の集合
#  @param   ?get_body  scalar   真の場合，本文を返す
#  @param   ?log       scalar   真の場合，ログを出力する
#
#
sub go {
  my ($self, $param) = self_param @_;
  my $addr_src      = $param->{from}      ||  $self->from      ||  '';
  my $addr_dest     = $param->{to}        ||  $self->to        ||  '';
  my $addr_cc       = $param->{cc}        ||  $self->cc        ||  '';
  my $addr_bcc      = $param->{bcc}       ||  $self->bcc       ||  '';
  my $addr_reply_to = $param->{reply_to}  ||  $self->reply_to  ||  '';
  my $subject       = $param->{subject}   ||  $self->subject   ||  '';
  my $body          = $param->{body}      ||  '';
  my $template      = $param->{template}  ||  {name => '', file => '', var => {}};
  my $get_body      = $param->{get_body}  ||  0;
  my $log           = $param->{log}       ||  0;
  my $test          = $param->{test}      ||  0;

  # $addr_dest の型チェック
  if (ref $addr_dest eq 'ARRAY') {
    # v ARRAYREF の場合は ',' で連結
    $addr_dest = join ',', @$addr_dest;
  }
  elsif (ref $addr_dest eq 'HASH') {
    # v HASHREF  の場合は，値の集合を ',' で連結
    $addr_dest = join ',', values %$addr_dest;
  }

  return 0
    unless ($addr_src
            && $addr_dest
            && $subject
            && ($body  ||  $template->{name}  ||  $template->{file})
           );

  if (!$body  &&  ($template->{name} || $template->{file})) {
    if ($template->{name}) {
      $template->{file} = sprintf('%s.mt',
                                  name2path $template->{name},
                                 );
    }

    my $mt =
      Text::MicroTemplate::Extended->new(
        include_path => $_conf->{PATH}{TEMPLATE},
        template_args => {
                          conf => $_conf,
                          ENV  => \%ENV,
                          var  => $template->{var},

                          SIGNATURE => $_conf->{MAIL}{SIGNATURE} || '',

                          ACTION_NAME => 'mail_sendmail',
                          VIEW_NAME   => $template->{name},
                         },
        use_cache => 1,
      );

    my $mailbodyfile = sprintf('%s/%s.mt',
                               $_conf->{PATH}{TEMPLATE},
                               name2path $template->{name},
                              );
    if (-f $mailbodyfile) {
      $body = $mt->render(name2path $template->{name})->as_string;
      # ^ utf-8 decoded
    }
    else {
      $body = $mt->render('_error')->as_string;
      # ^ utf-8 decoded
    }
  }

  $subject = encode('MIME-Header-ISO_2022_JP',
                    Encode::is_utf8($subject)
                      ? $subject : decode('utf-8', $subject),
                    #$subject,
                   );
  $subject =~ s{(?:\x0d\x0a?|\x0a)}{\x0a}g;
  $subject =~ s{\x0a}{\x0d\x0a}g;
  # ^ $subject のエンコード後の改行を CR+LF に統一する

  #$body = encode('jis', decode('utf-8', $body));
  $body = encode('jis', $body);
  $body =~ s{(?:\x0d\x0a?|\x0a)}{\x0a}g; $body =~ s{\x0a}{\x0d\x0a}g;
  # ^ $body の改行を CR+LF に統一する

  unless ($test) {
    my %mail = (
      smtp           => $_conf->{MAIL}{SERVER_SMTP} || 'localhost',
      'Content-Type' => 'text/plain; charset=iso-2022-jp',
      To             => $addr_dest,
      From           => $addr_src,
      Subject        => $subject,
      Message        => $body,
    );
    $mail{Cc}         = $addr_cc        if $addr_cc;
    $mail{Bcc}        = $addr_bcc       if $addr_bcc;
    $mail{'Reply-To'} = $addr_reply_to  if $addr_reply_to;

    sendmail(%mail);
    if ($log) {
      warn $Mail::Sendmail::log;
    }
    if ($Mail::Sendmail::error) {
      warn 'Mail::Sendmail error: ', $Mail::Sendmail::error;
      return 0;
    }
  }  # /unless( $test )

  $get_body  ?  $body  :  1;
}



1;
__END__
