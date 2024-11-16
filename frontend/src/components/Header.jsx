import { Link } from 'react-router-dom'
import { connectWallet } from '../services/blockchain'
import { truncate, useGlobalState } from '../store'

const Header = () => {
  const [connectedAccount] = useGlobalState('connectedAccount')
  return (
    <nav className="w-4/5 flex flex-row md:justify-center justify-between items-center py-4 mx-auto">
      <div className="md:flex-[0.5] flex-initial justify-center items-center">
        <Link to="/" className="text-white">
          <span className="px-2 py-1 font-bold text-3xl italic">ZKZK</span>
          <span className="py-1 font-semibold text-xl italic">.trade</span>
        </Link>
      </div>

      <ul
        className="md:flex-[0.5] text-white md:flex
      hidden list-none flex-row 
      items-center flex-initial"
      >
        <Link to="/" className="mx-4 cursor-pointer hover:underline">Market</Link>
        <Link to="/collections" className="mx-4 cursor-pointer hover:underline">My Domains</Link>
      </ul>

      {connectedAccount ? (
        <button
          className="shadow-xl shadow-black text-white
          bg-green-500 hover:bg-green-700 md:text-xs py-2 px-4
          rounded-full cursor-pointer text-xs sm:text-base"
        >
          {truncate(connectedAccount, 8, 8, 11)}
        </button>
      ) : (
        <button
          className="shadow-xl shadow-black text-white
          bg-green-500 hover:bg-green-700 md:text-xs p-2
          rounded-full cursor-pointer text-xs sm:text-base"
          onClick={connectWallet}
        >
          Connect Wallet
        </button>
      )}
    </nav>
  )
}
export default Header
