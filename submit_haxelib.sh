echo "Be sure to check version number in haxelib.json:"
cat haxelib.json | grep -i version
echo "lib.haxe.org currently has:"
curl -s http://lib.haxe.org/p/multicast | grep 'Current version'
sleep 1
read -r -p "Are you sure? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  rm -f multicast.zip
  cd src
  zip -rj ../multicast.zip ../haxelib.json ../README.md
  zip -r ../multicast.zip multicast
  cd ..
  haxelib submit multicast.zip
else
  echo "Cancelled"
fi
