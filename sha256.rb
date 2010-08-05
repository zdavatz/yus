require 'digest/sha2'
print "password: ", ARGV[0], "\n"
print "SHA256 encoding: ",Digest::SHA256.hexdigest(ARGV[0]),"\n"
