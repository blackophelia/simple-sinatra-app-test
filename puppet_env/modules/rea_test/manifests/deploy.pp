
class rea_test::deploy(
  $application_user     = hiera('rea_test::common::application_user'),
  $application_group    = hiera('rea_test::common::application_group'),
  $application_name     = hiera('rea_test::common::application_name'),
  $application_base_dir = hiera('rea_test::common::application_base_dir'),
) { 

  # choosing to checkout code directly from master here... would prefer to checkout
  # a branch, or use a packaged artefact (tarball or rpm?) to promote through all environments

  # will only execute this once, for the initial checkout
  exec {'clone_app':
    command => "/usr/bin/git clone https://github.com/tnh/${application_name}",
    cwd     => "${application_base_dir}",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => "${application_base_dir}/${application_name}",
    user    => "${application_user}",
    group   => "${application_group}",
    require => Package ['git'],
  }
  
  # subsequent invocations of puppet will pull changes, rather than checkout
  exec {'update_app':
    command => "/usr/bin/git pull -t origin master",
    cwd     => "${application_base_dir}/${application_name}",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    onlyif  => "/usr/bin/test -d ${application_base_dir}/${application_name}",
    user    => "${application_user}",
    group   => "${application_group}",
    require => Package ['git'],
  }

  file {"${application_base_dir}/${application_name}":
    ensure  => directory,
    mode    => '0775',
    require => [ Exec['clone_app'], Exec['update_app'], ],
  }

  file {'application_tmp_dir':
    path    => "${application_base_dir}/${application_name}/tmp",
    ensure  => directory,
    owner   => "${application_user}",
    group   => "${application_group}",
    require => [ Exec['clone_app'], Exec['update_app'], ],
  }

  file {'application_public_dir':
    path    => "${application_base_dir}/${application_name}/public",
    ensure  => directory,
    owner   => "${application_user}",
    group   => "${application_group}",
    require => [ Exec['clone_app'], Exec['update_app'], ],
  }

  exec {'restart_app':
    command => "/bin/touch ${application_base_dir}/${application_name}/tmp/restart.txt",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    user    => "${application_user}",
    group   => "${application_group}",
    require => [ File ['application_tmp_dir'], File['application_public_dir'], ],
  }

}

