# Definition: tomcat::config::context::parameter
#
# Configure Parameter elements in $CATALINA_BASE/conf/context.xml
#
# Parameters:
# - $ensure specifies whether you are trying to add or remove the
#   Parameter element. Valid values are 'true', 'false', 'present', and
#   'absent'. Defaults to 'present'.
# - $catalina_base is the base directory for the Tomcat installation.
# - $parameter_name is the name of the Parameter to be created, relative to
#   the java:comp/env context.
# - $value that will be presented to the application when requested from
#   the JNDI context.
# - $description is an optional string for a human-readable description
#   of this parameter entry.
# - Set $override to false if you do not want an <env-entry> for
#   the same parameter entry name to override the value specified here.
# - An optional array of $attributes_to_remove from the Parameter.
define tomcat::config::context::parameter (
  $ensure                  = 'present',
  $catalina_base           = $::tomcat::catalina_home,
  $parameter_name          = $name,
  $value                   = undef,
  $description             = undef,
  $override                = undef,
  $attributes_to_remove    = [],
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  if is_bool($override) {
    $_override = bool2str($override)
  } else {
    $_override = $override
  }

  validate_re($ensure, '^(present|absent|true|false)$')
  validate_absolute_path($catalina_base)

  validate_string(
    $parameter_name,
    $value,
    $description,
  )

  validate_array($attributes_to_remove)

  $base_path = "Context/Parameter[#attribute/name='${parameter_name}']"

  if $ensure =~ /^(absent|false)$/ {
    $changes = "rm ${base_path}"
  } else {
    if empty($value) {
      fail('$value must be specified')
    }

    $set_name  = "set ${base_path}/#attribute/name ${parameter_name}"
    $set_value = "set ${base_path}/#attribute/value ${value}"

    if ! empty($_override) {
      validate_re($_override, '(true|false)', '$override must be true or false')
      $set_override = "set ${base_path}/#attribute/override ${_override}"
    } else {
      $set_override = "rm ${base_path}/#attribute/override"
    }

    if ! empty($description) {
      $set_description = "set ${base_path}/#attribute/description \'${description}\'"
    } else {
      $set_description = "rm ${base_path}/#attribute/description"
    }

    if ! empty(any2array($attributes_to_remove)) {
      $rm_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${base_path}/#attribute/")
    } else {
      $rm_attributes_to_remove = undef
    }

    $changes = delete_undef_values(flatten([
      $set_name,
      $set_value,
      $set_override,
      $set_description,
      $rm_attributes_to_remove,
    ]))
  }

  augeas { "context-${catalina_base}-parameter-${name}":
    lens    => 'Xml.lns',
    incl    => "${catalina_base}/conf/context.xml",
    changes => $changes,
  }
}
