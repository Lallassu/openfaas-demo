# FaaS Demo - Using OpenFaaS / MySQL / Ceph
This is an engish version of the original blog-post at: https://www.cygate.se/blogg/faas-function-service-med-openfaas-mysql-ceph/

## Introduction
The new hot thing is FaaS, Function as a Service. Simply put, it is a way of executing functions in the cloud without your own webserver.
There are many benefits of this but one clear benefit is that you just have to pay for CPU-time used compared to pay for resources that you
might not use. Usually you have a webserver with pretty high margins resource wise, in order to handle sudden load. That extra margin is 
of course something you have to pay for. But using FaaS you just have to pay for the resource usage it takes to execute your functions.

However, there are some considerations that needs to be taken into account when developing using FaaS. Everything is stateless and each
function could be seen as a small micro-service that handles its specific task.

## Test of FaaS
To dig deeper into the subject I've setup a guide/demo to test FaaS. The guide will take use of OpenFaaS, Docker Swarm, MySQL and Ceph. Nginx
will also be used but just as a workaround to handle CORS (Cross-Origin Resource Sharing) in order to be able to reach objects outside of the
same domain. The guide will create a simple webpage that will be stored on a object-storage (in this case Ceph) using the Amazon S3 protocol.
MySQL will be used as a local database but could be any type of databas such as DBaaS (Database as a Service).
Docker Swarm will be used to setup the OpenFaaS stack on. Only one worker node will be used in this demo.

OpenFaaS works kinda like AWS Lambda but is a open source project. It's possible to deploy different kind of functions
using Ruby, Go, Java, NodeJS etc. In this demo Ruby will be used for all functions but each function could actually be 
written in different languages.

The guide should not be seen as a best practice of OpenFaaS and is rather a demo to elaborate it's functionality.

## Step 1
Docker is required on the host that is being used for the demo. The Docker Swarm can then easily be deployed with the following command.

    docker swarm init

Since we will just be using one worker node, we don't have to join any other Swarm-node to our cluster.

## Step 2
Clone the OpenFaaS repository in order to deploy OpenFaaS services onto our Swarm cluster.

    git clone https://github.com/openfaas/faas
    cd faas
    ./deploy_stack.sh

The stack is setup automatically using the above script and all containers can be seen using ''docker ps''.
[!img dockerps.png]

## Step 3
We are going to save data to a MySQL database so we need a database and a table. We call the database ''faas'' and the table ''users''.
    mysql -e "create database faas"
    mysql -D faas -e ”create table users (id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY(id), name varchar(255), date DATETIME)”

## Step 4
In our demo we will use Ruby together with MySQL and we require the gem ''mysql2''. The gem requires mysql-dev package
and in order to build this gem we also need build-base. Hence, we need to add this to the Dockerfile
for our executing envrionment. The dockerfile used is found in this repository [Dockerfile](Dockerfile).

The dockerfile could be built manually:
    docker build -t ruby:2.4-alpine3.6 .

## Step 5
Now to the fun part, functions! But in order to build new functions we need the OpenFaaS CLI. This is a tool that helps us
create new functions and also deploy them.

The CLI is easiest installed by downloading the shell-script and execute it:
    curl -sL https://cli.openfaas.com | sudo sh

In our demo we will create 3 functions. One function that adds new users to the database, one that removes users and one function
that list all users in the database.

Let's create a new function using the Ruby language:
    faas-cli new demo –lang ruby

A new directory called ''demo'' is now created and a file called ''demo.yml''. In the demo directory a boilerplate has been created called ''handler.rb'' and a Gemfile.
Since we are going to use mysql2 gem we add this to the Gemfile [Gemfile example](delete_user/Gemfile).

''demo.yml'' includes configuration for our functions. It specifies which functions we have defined and also environment variables.
We will setup environment variables for our database (IP/host, username, password, database-name). We create the [env.yml](env.yml) for this purpose.
Make sure to change to your values in this file.

As a side-note; It is also possible to use secrets in Docker Swarm or Kubernetes instead of specifiying variables this way, which is the preferred way
to handle secrets in a production environment.

We will point out the environment-file from our demo.yml configuration file. Each function will take use of the environment variables in their execution environment.

## Step 6
Time to create our actual functions. In the [demo.yml](demo.yml) configuration file we have specified each function, what language it uses,
which handler to use and which environment file to use. We also specify the gateway for our OpenFaaS stack which is localhost:8080 since we 
are using a local OpenFaaS setup. The functions we specify here will be created in step 7.

## Step 7
Time to write some code! We copy our demo directory that was created in step 3 into 3 new directories. One for each function with
the same name as the function itself.
    cp –r demo new_user
    cp –r demo delete_user
    cp –r demo list_users
    rm –rf demo
As a last step we remove the demo directory which will no longer be used, since it was just our boilerplate.

The first function is new_user/handler.rb which will respond to a POST request. It will create a user in the database with the provided name
in the request. Note that we have skipped all forms of security in this case, as said before, it's just a demo!

The code for the new user function is here: [new_user](new_user/handler.rb).

The second function will delete the user with given name, also through a post request. Note that the code will remove all users with the same name in the database.

The code for the delete user function is here: [delete_user](delete_user/handler.rb).

And our last function will just list all users in the database and can be found here: [list_users](list_users/handler.rb).

Note that each function take use of the environment variables that we specified in our ''env.yml''.

## Step 8
Now we shall deploy our newly created functions to OpenFaaS. This requires that we build our environment:
    faas-cli build -f demo.yml
Then we can deploy the functions:
    faas-cli deploy -f demo.yml

## Step 9
Time to test our functions, using curl.
[!img](deploy_and_test.png)

## Step 10
Let's create a simple webpage that takes use of our functions. We create a simple HTML page with some Javascript that issues AJAX requests
towards our OpenFaaS stack. Make sure to change the URL to your host.
View the code here: [index.html](index.html).

This is where we use our nginx server as a workaround for CORS. The requests goes through the Nginx server which acts as a proxy towards our OpenFaaS.
The Nginx server allows for CORS and we can make requests outside of our domain where the webpage is located. This is not recommended in a production environment.

View the nginx configuration here: [nginx.conf](nginx.conf)

Lets add our index.html file to our Ceph account using the simple s3cmd application. We create a bucket called ''faas'' and upload the index.html file to it. Then we set ACL rules to public 
in order to be able to access the file without logging in.

    s3cmd mb s3://faas
    s3cmd put index.html s3://faas/
    s3cmd setacl –acl-public s3://faas/index.html

For my Ceph setup I will reach my file using the link http://ceph.magstar.cygate.io:7480/cexhbeao:faas/index.html. This will
of course be different in your case. The result looks like the below screenshot:
[!img](site.png)

On the page we can now add, delete and list users dynamically.

## Conclusion
The cool stuff with Function as a Service combined with an object storage is that we can host a small webpage with database functionality
without having a webapp that handles it. And also, I don't need my own webserver!

If we skip the workaround part of nginx for this guide. All we need would be an account from a FaaS provider, an object-storage account and a database account.
Then all I would have to pay for would be 4KB of storage and CPU-time for each request by my visitors of the site. Note that some providers charge per request towards
object-storage as well.

This guide might not bee suitable for most people but it's a basic example how to use FaaS in a cheap and simple way. It also gives an example of what can be 
done using FaaS, for example heavy duty functions such as movie-conversion or image-conversion that might otherwise demand high load on the usual webserver. In this case
these high demanding functions will be offloaded to a FaaS provider!

## Links
https://github.com/openfaas/faas
https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS



