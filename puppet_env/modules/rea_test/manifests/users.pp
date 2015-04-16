class rea_test::users (
  $application_group  = hiera('rea_test::common::application_group'),
  $application_user   = hiera('rea_test::common::application_user'),
  $web_server_group   = hiera('rea_test::common::web_server_group'),
  $web_server_user    = hiera('rea_test::common::web_server_user'),
) {


  group { "${application_group}":
    ensure     => present,
    gid        => '1001',
  }
  group { "${web_server_group}":
    ensure     => present,
    gid        => '1002',
  }

  user { "${application_user}":
    ensure     => present,
    comment    => "Application User",
    uid        => '1001',
    gid        => "${application_group}",
    shell      => '/bin/bash',
    managehome => false,
    password   => 'NP',
  }

  user { "${web_server_user}":
    ensure     => present,
    comment    => "WebServer Runtime User",
    uid        => '1002',
    gid        => "${web_server_group}",
    groups     => [ "${application_group}", ],
    shell      => '/bin/bash',
    managehome => false,
    password   => 'NP',
  }

}
