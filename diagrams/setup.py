from diagrams import Diagram, Cluster
from diagrams.aws.compute import EC2
from diagrams.aws.general import User
from diagrams.aws.general import InternetGateway
from diagrams.aws.network import RouteTable
from diagrams.aws.general import General
from diagrams.aws.general import SDK





with Diagram("Development Environment"):
    with Cluster("IaC"):

        terra = SDK("Terraform")
        user = General("ssh.config.tpl") >> terra
        userdata = General("userdata.tpl")
             
    with Cluster("VPC"):
        ig = InternetGateway("Internet Gateway")
        table = RouteTable("Route Table")

        with Cluster("Public Security Group"):
            with Cluster("Public Subnet"):
                ec2 = EC2("EC2")

    user >> userdata
    userdata >> user
    user >> ig >> table >> ec2
    userdata >> ec2
    