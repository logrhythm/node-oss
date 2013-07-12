# ### Log Package
# this formats the packages found logs in the console

logPackage = (module, license, special) ->
  # the min length for module name tab region
  moduleLine      = 25
  # the absolute length for license tab region
  licenseLine     = 20

  # set module string for output at min length
  consoleModule   = module
  consoleModule  += ' ' for i in [0...(moduleLine-module.length)]
    
  # if the license name is super long truncate the beginning of the string
  # with an ellipsis
  license         = '...'+license.substr(license.length-(licenseLine-3), license.length) if license.length > licenseLine
  consoleLicense  = license
  # set license string for output at absolute length
  consoleLicense += ' ' for i in [0...(licenseLine-license.length)]

  # OUTPUT
  console.log "module : #{consoleModule} \t| license : #{consoleLicense} #{'\t| '+special if special}"

module.exports = logPackage