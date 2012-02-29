maintainer        "Peritor GmbH"
maintainer_email  "scalarium@peritor.com"
license           "Apache 2.0"
description       "Installs and configures phpmyadmin on Ubuntu"
version           "0.2"
recipe            "phpmyadmin::default", "Installs phpmyadmin"
recipe            "phpmyadmin::configure", "Updates phpmyadmin db config"
recipe            "phpmyadmin::privileges", "Updates privileges of db"

supports 'ubuntu'
