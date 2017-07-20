class PGP
  def self.upload_key(key, user_id)
    # temp = key.gsub("-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n", "")
    # key  = temp.gsub("=\r\n-----END PGP PUBLIC KEY BLOCK-----", "")
    if File.directory?("public/pgp/users/#{user_id}")
      File.delete("public/pgp/users/#{user_id}/key.txt") if File.exist?("public/pgp/users/#{user_id}/key.txt")
      File.delete("public/pgp/users/#{user_id}/publickey.asc") if File.exist?("public/pgp/users/#{user_id}/publickey.asc")

      pgp_key = File.open("public/pgp/users/#{user_id}/key.txt", 'w') {|f| f.write("#{key}") }
      pgp_key = File.open("public/pgp/users/#{user_id}/publickey.asc", 'w') {|f| f.write("#{key}") }

      file = File.open("public/pgp/users/#{user_id}/key.txt")
      info = GPGME::Key.import(file)
    else
      FileUtils.mkdir_p "public/pgp/users/#{user_id}"
      pgp_key = File.open("public/pgp/users/#{user_id}/key.txt", 'w') {|f| f.write("#{key}") }
      pgp_key = File.open("public/pgp/users/#{user_id}/publickey.asc", 'w') {|f| f.write("#{key}") }

      file = File.open("public/pgp/users/#{user_id}/key.txt")
      info = GPGME::Key.import(file)
    end
  end
end
