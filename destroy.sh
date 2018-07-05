heroku pipelines:destroy cicd
heroku apps:destroy -a cicddev -c cicddev
heroku apps:destroy -a cicdstaging -c cicdstaging
heroku apps:destroy -a cicdprod -c cicdprod
