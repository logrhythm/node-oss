{spawn} = require 'child_process'
fs      = require 'fs'
$       = require('jquery').create()

# container for list
openSource    = []
# async state
npmParsed     = false
extraParsed   = false

# once processing is complete output file
writeFile = ->
  openSource.sort (a,b) -> 
    return -1 if a[0] < b[0]
    return 1  if a[0] > b[0]
    return 0
  now = new Date()
  dateString  = "#{now.getMonth()+1}-#{now.getDate()}-#{now.getFullYear()}.#{now.getHours()}-#{now.getMinutes()}"
  fileString  = 'Project,License,Type,Npm Depth\n'
  fileString += "#{oss[0]},#{oss[1]},#{oss[2]},#{oss[3] or ''}\n" for oss in openSource
  fileString  = fileString.substr(0, fileString.length-1)
  fileName    = "openSource-#{dateString}.csv"
  fs.writeFile fileName, fileString, (err) ->
    if err then console.log err else console.log "Unique open source dependencies saved to `#{fileName}`"

logPackage = (module, license, special) ->
  moduleLine      = 25
  licenseLine     = 20
  consoleModule   = module
  consoleModule  += ' ' for i in [0...(moduleLine-module.length)]
  license         = '...'+license.substr(license.length-(licenseLine-3), license.length) if license.length > licenseLine
  consoleLicense  = license
  consoleLicense += ' ' for i in [0...(licenseLine-license.length)]
  console.log "module : #{consoleModule} \t| license : #{consoleLicense} #{'\t| '+special if special}"

# parse and push from npm json
npmParseAndPush = (data) ->
  # get project npm dependencies
  {dependencies} = JSON.parse String data
  # parse recursively to get all project unique npm modules
  modules       = []
  findModules   = (npm, deep) ->
    for k, v of npm 
      k = [k] unless deep 
      modules.push k 
      findModules v.dependencies, true if v.dependencies
  findModules dependencies

  filteredOSS   = []
  filteredOSS.push module for module in modules when filteredOSS.indexOf(module) is -1  

  pushedIndex     = 0
  jQueryScrape    = (module, deep) ->
    
    $.get "https://npmjs.org/package/#{module}", (data) ->
      license = null
      npmPage = $ data
      debug   = true

      testforlicense = (str) ->
        isMIT     = if str.indexOf(' MIT ')  is -1 then false else true
        unless isMIT 
          isMIT   = if str.indexOf('a copy of this software and associated documentation files (the') is -1 then false else true
        isBSD     = if str.indexOf('BSD')    is -1 then false else true
        isApache  = if str.indexOf('Apache') is -1 then false else true
        isTwo     = if str.indexOf('2.0')    is -1 then false else true
        res = null
        res = 'MIT'        if isMIT    and not isBSD and not isApache
        res = 'BSD'        if isBSD    and not isMIT and not isApache
        res = 'Apache 2.0' if isApache and isTwo and not isMIT and not isBSD
        license = res if res

      firster = true
      pushAndInc = (module, license) ->
        return unless firster
        firster = false
        logPackage module, license, "#{pushedIndex+1} of #{filteredOSS.length} npm #{if deep then '' else'\t| TOP LEVEL' }"
        temp    = [module, license, 'NPM Package']
        temp.push 'Top Level' unless deep 
        openSource.push temp
        pushedIndex++
        if pushedIndex is filteredOSS.length
          # stateness
          npmParsed = true
          # `writeFile` if vendors are parsed as well
          writeFile() if extraParsed

      lastCall = (module, num) ->
        unless license
          pushAndInc module, "https://npmjs.org/package/#{module}"
          license = true

      unless license
        npmPage.find('table.metadata th').each ->
          that = $ @          
          if that.text() is 'License'
            license = that.siblings('td').eq(0).find('a').text()
            pushAndInc module, license if license

      unless license
        readme = npmPage.find('#readme').html() 
        if readme
          testforlicense readme
          pushAndInc module, license if license

      repoFound = false
      
      unless license          
                  
        npmPage.find('table.metadata th').each ->            
          that = $ @     
          if that.text().indexOf('Repository') is 0               
            github = that.find('a').attr('href')              
            if github                
              if github.indexOf('github') is -1
                console.log 'NOT GIT '+ github
                lastCall module                                  
              else                                  
                repoFound         = true                                         
                github            = github.split '//'
                
                gitEndPoints      = ['LICENSE','LICENCE','README.mdown','README.md']                  
                failIndex         = 0

                checkGit          = (endPoint, failCallback) ->
                  filePath        = "https://raw.#{github[1]}/master/#{endPoint}"                    
                  $.get(filePath, (data) ->
                    testforlicense data.replace /(\r\n|\n|\r)/gm, ''
                    if license
                      pushAndInc module, license 
                    else failCallback()
                  ).fail -> failCallback()

                for endPoint in gitEndPoints
                  checkGit endPoint, ->
                    failIndex++
                    if failIndex is gitEndPoints.length 
                      lastCall module, 1 
            
            else lastCall module, 2
        
      lastCall module, 3 unless repoFound
          
  # push unique npm modules to list 
  for module in filteredOSS
    if typeof module is 'string'   
      jQueryScrape module.toLowerCase(), true
    else
      jQueryScrape module[0].toLowerCase(), false

# parse and push from frontend vendor list
vendorParseAndPush = (err, data, callback) ->
  # parse lines that contain vendor stuff
  parsetarget = data.split('#').filter (line) ->
    return false unless line.substr(0, 2) is ' ['
    return true
  # parse vendor name from line
  parsetarget[i] = parsetarget[i].split(']') for i in [0...parsetarget.length]
  vendors        = parsetarget.map (item) -> item[0].replace(' [','')
  licenses       = parsetarget.map (item) -> item[1].split('|')[1].trim().replace('\n','')
  pairs          = for i in [0...vendors.length]
    [vendors[i].toLowerCase(), licenses[i], 'Front End Project']
  # push unique vendor files to list
  filteredOSS = []
  filteredOSS.push pair for pair in pairs when filteredOSS.indexOf(pair) is -1
  for module, i in filteredOSS
    logPackage module[0], module[1], "#{i+1} of #{filteredOSS.length} frontend"
    openSource.push module 

  callback()

# parse and push from json file
extraParseAndPush = (err, data) ->
  unless data
    extraParsed = true
    writeFile() if npmParsed
    return console.log 'OPTIONAL `osslist.json` NOT FOUND' 
  {OSS, ConnectAsset} = JSON.parse String data
  i       = 0
  total   = 0
  total++ for k, v of OSS 

  for project, vals of OSS 
    logPackage project.toLowerCase(), vals.license, "#{i+1} of #{total} OSS"
    openSource.push [project.toLowerCase(), vals.license, 'OSS']
    i++

  if ConnectAsset
    j     = 0
    for asset in ConnectAsset
      fs.readFile asset, 'utf8', (err, data) -> 
        throw new Error "ConnectAsset #{asset} NOT FOUND" unless data
        vendorParseAndPush err, data, ->
          j++
          if j is ConnectAsset.length 
            extraParsed = true
            writeFile() if npmParsed
  else
    extraParsed = true
    writeFile() if npmParsed

# spawn `npm list --json=true` process
list = spawn 'npm', ['list', '--json=true']
# `npm list` callback
list.stdout.on 'data', npmParseAndPush
# read `osslist.json` 
fs.readFile 'osslist.json', 'utf8', extraParseAndPush