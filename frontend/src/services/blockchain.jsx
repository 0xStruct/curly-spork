import abi from '../abis/src/contracts/Auction.sol/Auction.json'
import address from '../abis/contractAddress.json'
import { getGlobalState, setGlobalState } from '../store'
import { ethers } from 'ethers'

const { ethereum } = window
const ContractAddress = address.address
const ContractAbi = abi.abi
let tx

const toWei = (num) => ethers.utils.parseEther(num.toString())
const fromWei = (num) => ethers.utils.formatEther(num)

const getEthereumContract = async () => {
  const connectedAccount = getGlobalState('connectedAccount')

  if (connectedAccount) {
    const provider = new ethers.providers.Web3Provider(ethereum)
    const signer = provider.getSigner()
    const contract = new ethers.Contract(ContractAddress, ContractAbi, signer)

    return contract
  } else {
    return getGlobalState('contract')
  }
}

const isWallectConnected = async () => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const accounts = await ethereum.request({ method: 'eth_accounts' })
    setGlobalState('connectedAccount', accounts[0]?.toLowerCase())

    window.ethereum.on('chainChanged', (chainId) => {
      window.location.reload()
    })

    window.ethereum.on('accountsChanged', async () => {
      setGlobalState('connectedAccount', accounts[0]?.toLowerCase())
      await isWallectConnected()
      await loadCollections()
      await logOutWithCometChat()
      await checkAuthState()
        .then((user) => setGlobalState('currentUser', user))
        .catch((error) => setGlobalState('currentUser', null))
    })

    if (accounts.length) {
      setGlobalState('connectedAccount', accounts[0]?.toLowerCase())
    } else {
      alert('Please connect wallet.')
      console.log('No accounts found.')
    }
  } catch (error) {
    reportError(error)
  }
}

const connectWallet = async () => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' })
    setGlobalState('connectedAccount', accounts[0]?.toLowerCase())
  } catch (error) {
    reportError(error)
  }
}

const createNftItem = async ({
  name,
  description,
  price,
}) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    console.log("createAuction", name, description, price)
    tx = await contract.createAuction(
      name,
      description,
      toWei(price),
      {
        from: connectedAccount,
        value: toWei(0.02),
      },
    )
    await tx.wait()
    await loadAuctions()
  } catch (error) {
    console.log("createAuction error", error)
    reportError(error)
  }
}

const updatePrice = async ({ domain, price }) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    tx = await contract.changePrice(domain, toWei(price), {
      from: connectedAccount,
    })
    await tx.wait()
    await loadAuctions()
  } catch (error) {
    reportError(error)
  }
}

const offerItemOnMarket = async ({
  domain,
  biddable,
  sec,
  min,
  hour,
  day,
}) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    tx = await contract.offerAuction(domain, biddable, sec, min, hour, day, {
      from: connectedAccount,
    })
    await tx.wait()
    await loadAuctions()
  } catch (error) {
    reportError(error)
  }
}

const buyNFTItem = async ({ domain, price }) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    tx = await contract.buyAuctionedItem(domain, {
      from: connectedAccount,
      value: toWei(price),
    })
    await tx.wait()
    await loadAuctions()
    await loadAuction(domain)
  } catch (error) {
    reportError(error)
  }
}

const bidOnNFT = async ({ domain, price }) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    tx = await contract.placeBid(domain, {
      from: connectedAccount,
      value: toWei(price),
    })

    await tx.wait()
    await getBidders(domain)
    await loadAuction(domain)
  } catch (error) {
    reportError(error)
  }
}

const claimPrize = async ({ domain, id }) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    tx = await contract.claimPrize(domain, id, {
      from: connectedAccount,
    })
    await tx.wait()
    await getBidders(domain)
  } catch (error) {
    reportError(error)
  }
}

const loadAuctions = async () => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const contract = await getEthereumContract()
    const auctions = await contract.getLiveAuctions()
    setGlobalState('auctions', structuredAuctions(auctions))
    setGlobalState(
      'auction',
      structuredAuctions(auctions).sort(() => 0.5 - Math.random())[0],
    )
  } catch (error) {
    reportError(error)
  }
}

const loadAuction = async (id) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const contract = await getEthereumContract()
    const auction = await contract.getAuction(id)
    setGlobalState('auction', structuredAuctions([auction])[0])
  } catch (error) {
    reportError(error)
  }
}

const getBidders = async (id) => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const contract = await getEthereumContract()
    const bidders = await contract.getBidders(id)
    setGlobalState('bidders', structuredBidders(bidders))
  } catch (error) {
    reportError(error)
  }
}

const loadCollections = async () => {
  try {
    if (!ethereum) return alert('Please install Metamask')
    const connectedAccount = getGlobalState('connectedAccount')
    const contract = await getEthereumContract()
    const collections = await contract.getMyAuctions({ from: connectedAccount })
    console.log("collections", collections)
    setGlobalState('collections', structuredAuctions(collections))
  } catch (error) {
    reportError(error)
  }
}

const structuredAuctions = (auctions) =>
  auctions
    .map((auction) => ({
      domain: auction.domain.toNumber(),
      owner: auction.owner.toLowerCase(),
      seller: auction.seller.toLowerCase(),
      winner: auction.winner.toLowerCase(),
      name: auction.name,
      description: auction.description,
      duration: Number(auction.duration + '000'),
      image: auction.image,
      price: fromWei(auction.price),
      biddable: auction.biddable,
      sold: auction.sold,
      live: auction.live,
    }))
    .reverse()

const structuredBidders = (bidders) =>
  bidders
    .map((bidder) => ({
      timestamp: Number(bidder.timestamp + '000'),
      bidder: bidder.bidder.toLowerCase(),
      price: fromWei(bidder.price),
      refunded: bidder.refunded,
      won: bidder.won,
    }))
    .sort((a, b) => b.price - a.price)

const reportError = (error) => {
  console.log(error.message)
  throw new Error('No ethereum object.')
}

export {
  isWallectConnected,
  connectWallet,
  createNftItem,
  loadAuctions,
  loadAuction,
  loadCollections,
  offerItemOnMarket,
  buyNFTItem,
  bidOnNFT,
  getBidders,
  claimPrize,
  updatePrice,
}
