require 'ethereum.rb'

client = Ethereum::HttpClient.new('https://autumn-dark-mountain.ropsten.quiknode.pro/1d64e0572b48069443e3fb187fad19eba44e9d53/')

contract = Ethereum::Contract.create(
  name: "ColorNFTs",
  truffle: { paths: [ '../' ] },
  client: client
)

puts contract.deploy_and_wait
