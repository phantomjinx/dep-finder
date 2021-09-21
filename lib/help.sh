do_help() {
  cat - <<EOT

Global options:
-h  --help               Show this help
    --jdeps              Path to the jdeps binary (optional)

Single jar options:
-j  --jar                Path to the jar file to be tested (required)
-f  --full               Display full results from jdeps rather than default jar listing (optional)
-r  --repo               Directory filesystem of jar files to add to the classpath (optional)
-cp --classpath          Append an additional classpath string (optional)

Single image options:
-d  --docker             Path to the docker client (optional)
-i  --image              Reference to the image to be tested - image:tag (required)
-j  --jar                Name of the root jar file to be tested (optional)
                         By specifying this, the additional jar options above can alsone used.

Single pom options:
-m  --maven              Path to the maven binary (optional)
-p  --pom                Path to the source pom file
-f  --full               Display full results from maven rather than default jar listing (optional)

EOT
}
