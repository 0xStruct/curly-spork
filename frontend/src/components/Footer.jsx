import React from 'react'

const Footer = () => {
  return (
    <div className="w-4/5 flex sm:flex-row flex-col justify-between items-center my-4 mx-auto py-5">
      <div className="hidden sm:flex flex-1 justify-start items-center space-x-12">
        <p className="text-white text-base text-center cursor-pointer">
          Market
        </p>
      </div>

      <p className="text-white text-right text-xs">
        Built at ETHBangkok
      </p>
    </div>
  )
}

export default Footer
