import "./App.css";
import "bootstrap/dist/css/bootstrap.min.css";
import Navbar from "./components/Navbar";
import { useState, useEffect } from "react";

import Web3 from "web3";
import { newKitFromWeb3 } from "@celo/contractkit";
import BigNumber from "bignumber.js";
import IERC from "./contract/IERC.abi.json";
import Marketplace from "./contract/Marketplace.abi.json";
import AddFestival from "./components/AddFestival";
import Festival from "./components/Festival";

const ERC20_DECIMALS = 18;

const contractAddress = "0xbA62AEb4c9a42154E1a231b399aFa51B4b4C8594";
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

function App() {
	const [contract, setcontract] = useState(null);
	const [address, setAddress] = useState(null);
	const [kit, setKit] = useState(null);
	const [cUSDBalance, setcUSDBalance] = useState(0);
	const [festivals, setFestivals] = useState([]);

	const connectToWallet = async () => {
		if (window.celo) {
			try {
				await window.celo.enable();
				const web3 = new Web3(window.celo);
				let kit = newKitFromWeb3(web3);

				const accounts = await kit.web3.eth.getAccounts();
				const user_address = accounts[0];

				kit.defaultAccount = user_address;

				await setAddress(user_address);
				await setKit(kit);
			} catch (error) {
				console.log(error);
			}
		} else {
			console.log("Error Occurred");
		}
	};

	useEffect(() => {
		connectToWallet();
	}, []);

	useEffect(() => {
		if (kit && address) {
			getBalance();
		}
	}, [kit, address]);

	useEffect(() => {
		if (contract) {
			getFestivals();
		}
	}, [contract]);

	const getBalance = async () => {
		try {
			const balance = await kit.getTotalBalance(address);
			const USDBalance = balance.cUSD
				.shiftedBy(-ERC20_DECIMALS)
				.toFixed(2);
			const contract = new kit.web3.eth.Contract(
				Marketplace,
				contractAddress
			);
			setcontract(contract);
			setcUSDBalance(USDBalance);
		} catch (error) {
			console.log(error);
		}
	};

	const getFestivals = async () => {
		const programmesLength = await contract.methods.getProgrammesLength().call();
		const _fest = [];
		for (let index = 0; index < programmesLength; index++) {
			let _festivals = new Promise(async (resolve, reject) => {
				let festival = await contract.methods.readProgramme(index).call();

				resolve({
					index: index,
					owner: festival[0],
					url: festival[1],
					theme: festival[2],
					 description: festival[3],
					location:festival[4],
					price:festival[5],
					sold:festival[6]
				});
			});
			_fest.push(_festivals);
		}
		const _festivals = await Promise.all(_fest);
		setFestivals(_festivals);
		 
	};
	
	 
	

	const AddFestival = async (_url, _theme, _description, _location, price) => {
		const _price = new BigNumber(price)
			.shiftedBy(ERC20_DECIMALS)
			.toString();
		try {
			await contract.methods
				.addProduct(_url, _theme, _description, _location, _price)
				.send({ from: address });
			getFestivals();
		} catch (error) {
			console.log(error);
		}
	};

 
 
	const buySlot = async (_index) => {
		try {
			const cUSDContract = new kit.web3.eth.Contract(
				IERC,
				cUSDContractAddress
			);

			await cUSDContract.methods
				.approve(contractAddress, festivals[_index].price)
				.send({ from: address });
			await contract.methods.bookSlot(_index).send({ from: address });
			getFestivals();
			getBalance();
		} catch (error) {
			console.log(error);
		}
	};

	return (
		<div>
				<Navbar balance={cUSDBalance} />

				<Festival
					festivals={festivals}
					buySlot={buySlot}
					onlyOwner={address}
				
				/>
				<AddFestival AddProduct={AddFestival} /> 
			</div>
	
	
);
	
}

export default App;