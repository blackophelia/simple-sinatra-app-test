#
# This class is responsible for installation and configuration of packages
# and other system stuff required to get the sinatra app up and running
#
class rea_test::system(
  $application_user     = hiera('rea_test::common::application_user'),
  $application_group    = hiera('rea_test::common::application_group'),
  $web_server_user      = hiera('rea_test::common::web_server_user'),
  $web_server_group     = hiera('rea_test::common::web_server_group'),
  $application_base_dir = hiera('rea_test::common::application_base_dir'),
  $application_name     = hiera('rea_test::common::application_name'),
  $passenger_root,
  $ruby_home,
  $host_ip,
) {

  realize ( Group["${application_group}"] )
  realize ( Group["${web_server_group}"] )
  realize ( User["${application_user}"] )
  realize ( User["${web_server_user}"] )

  #
  # install apache, passenger and related dependencies
  #
  package {"httpd": 
    ensure        => installed,
    allow_virtual => false,
  }
  package {"httpd-devel": 
    ensure        => installed,
    allow_virtual => false,
    require       => Package['httpd'],
  }

  exec { 'install_gpg_key':
    command => '/bin/rpm --import http://passenger.stealthymonkeys.com/RPM-GPG-KEY-stealthymonkeys.asc',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => '/etc/pki/rpm-gpg/RPM-GPG-KEY-passenger',
    require => Package['httpd'],
  }

  package { 'passenger-release':
    ensure        => installed,
    allow_virtual => false,
    require       => Exec['install_gpg_key'],
  }

  #This fails, so have gone for an alternative installation instead
#  package { 'mod_passenger':
#    ensure        => installed,
#    allow_virtual => false,
#    require       => Package['passenger-release'],
#  }

  # This is the alternative to installing mod_passenger.... ugly but not going
  # to try and downgrade the ruby patch level from the default.

  package {'gcc-c++':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['httpd'],
  }
  package {'libcurl-devel':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['gcc-c++'],
  }
  package {'openssl-devel':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['libcurl-devel'],
  }
  package {'zlib-devel':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['openssl-devel'],
  }
  package {'ruby-devel':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['zlib-devel'],
  }

  exec { 'passenger-install-apache2-module':
    command => '/usr/bin/passenger-install-apache2-module --auto',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => "${passenger_root}/buildout/apache2/mod_passenger.so",
    require => Package['ruby-devel'],
  }

  #
  # configure apache
  #

  # remove the default welcome.conf
  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => absent,
    notify  => Service['httpd'],
  }

  # security specific - write out an updated httpd.conf
  file { "/etc/httpd/conf/httpd.conf":
    ensure  => present,
    content => template('rea_test/httpd.conf.erb'),
    owner   => 'root',
    group   => 'root',
    notify  => Service['httpd'],
  }

  # application specific
  file { "/etc/httpd/conf.d/rea_test.conf":
    ensure  => present,
    content => template('rea_test/rea_test.conf.erb'),
    owner   => 'root',
    group   => 'root',
    require => File['/etc/httpd/conf/httpd.conf'],
    notify  => Service['httpd'],
  }

  service { 'httpd':
    ensure      => 'running',
    hasrestart  => true,
    hasstatus   => true,
    enable      => true,
  }

  # lock it all down...
  # TODO: need to lock all the things, sort out permissions for riunning web app, accessing webapp from laptop connecting to VM

  # For the app now..
  package {'git':
    ensure        => installed,
    allow_virtual => false,
    require       => Package['httpd'],
  }

  package {'sinatra':
    ensure   => installed,
    provider => gem,
  }

  file {"${application_base_dir}":
    ensure  => directory,
    owner   => 'root',
    group   => "${application_group}",
    mode    => '0775',
    require => Package['sinatra'],
  }

}

