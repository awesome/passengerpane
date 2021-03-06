(load "test_helper")

(describe "CLI" `(
  (before (do ()
    (set @cli ((CLI alloc) init))
  ))
  
  (it "is not authorized by default" (do ()
    (~ (@cli isAuthorized) should be:false)
  ))
))

(describe "CLI, when unauthorized" `(do
  (before (do ()
    (set @cli ((CLI alloc) init))
    (@cli setPathToCLI:pathToCLI)
  ))
  
  (it "lists currently configured applications" (do ()
    (set applications (@cli listApplications))
    (~ (applications count) should be:3)
    (set hostnames `())
    (for ((set index 0) (< index (applications count)) (set index (+ index 1)))
      (set application (applications objectAtIndex:index) description)
      (set hostnames (append hostnames (list (application host))))
    )
    (~ hostnames should equal:`("manager.boom.local" "scoring.boom.local" "diagnose.local"))
  ))
  
  (it "restarts an application" (do ()
    (set applications (@cli listApplications))
    (@cli restart:(applications objectAtIndex:0))
    
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"restart\", \"manager.boom.local\"]")
  ))
  
  (it "knows whether the Passenger module is installed" (do ()
    (set installed (@cli isPassengerModuleInstalled))
    (~ installed should equal:false)
  ))
))

(describe "CLI, when authorized" `(do
  (before (do ()
    (set @cli ((CLI alloc) init))
    (@cli setPathToCLI:pathToCLI)
    (@cli fakeAuthorize)
    
    (set attributes (NSMutableDictionary dictionary))
    (attributes setValue:"test.local" forKey:"host")
    (attributes setValue:"assets.test.local" forKey:"aliases")
    (attributes setValue:"/path/to/test" forKey:"path")
    (attributes setValue:"production" forKey:"environment")
    (attributes setValue:"/path/to/test.conf" forKey:"config_filename")
    (set @application ((Application alloc) initWithAttributes:attributes))
  ))
  
  (it "adds a new application" (do ()
    (@cli add:@application)
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"add\", \"/path/to/test\", \"-path\", \"/path/to/test\", \"-environment\", \"production\", \"-host\", \"test.local\", \"-config_filename\", \"/path/to/test.conf\", \"-aliases\", \"assets.test.local\"]")
  ))
  
  (it "updates an application" (do ()
    (@cli update:@application)
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"update\", \"test.local\", \"-path\", \"/path/to/test\", \"-environment\", \"production\", \"-host\", \"test.local\", \"-config_filename\", \"/path/to/test.conf\", \"-aliases\", \"assets.test.local\"]")
  ))
  
  (it "deletes an application" (do ()
    (@cli delete:@application)
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"delete\", \"test.local\"]")
  ))
  
  (it "restarts an application" (do ()
    (@cli restart:@application)
    (set arguments (NSString stringWithContentsOfFile:pathToCLIArguments encoding:NSUTF8StringEncoding error:nil))
    (~ arguments should equal:"[\"restart\", \"test.local\"]")
  ))
))

((Bacon sharedInstance) run)