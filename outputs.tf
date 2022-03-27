output "ssh-with-docker-user" {
  value = join(
    "\n",
    [for i in oci_core_instance._ :
      format(
        "ssh -l docker -p 22 -i %s # %s",
        i.public_ip,
        i.display_name
      )
    ]
  )
}
