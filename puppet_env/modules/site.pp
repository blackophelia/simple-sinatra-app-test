
node "localhost.home.gateway" {
  class {'rea_test::users': }  ->
  class {'rea_test::system': } ->
  class {'rea_test::deploy': } 
}
