import { createStore } from "vuex";
import createPersistedState from "vuex-persistedstate";
import swal from "sweetalert2";
import detectEthereumProvider from "@metamask/detect-provider";
import { localhost } from "viem/chains";
import {
  createWalletClient,
  custom,
  createPublicClient,
  decodeEventLog,
  toHex,
} from "viem";
import {
  NFT_ABI,
  TOKEN_ABI,
  IP_HOLDER_ABI,
  IP_REGISTRAR_ABI,
} from "@/assets/abis";

const axios = require("axios");
const BigNumber = require("bignumber.js");
const addresses = require("../../../contracts/deploy-out/deployment.json");

export default createStore({
  plugins: [createPersistedState()],
  state: {
    MMSDK: null,
    connected: false,
    account: "",
    isLoading: false,
    provider: null,
    chainId: null,
    explode: false,
    web3: null,
    ipDeploymentDetails: {},
    publicClient: {},
    walletClient: {},
    ipContract: {},
    nftContract: {},
    tokenContract: {},
    ipRegistrarContract: {},
    ips: [],
    selectedIP: "",
    paymentTokenDetails: {},
    showIpDialog: false,
    issuedLicenses: [],
    issuedIPs: [],
    showPDFDialog: false,
    pdfURL: "",
    allIPS: [],
    purchasedLicenses: [],
  },
  getters: {},
  mutations: {},

  actions: {
    async checkPaymentTokenApproval(_context, data) {
      const selectedIP = data.ip;
      this.state.isLoading = true;
      const approved = await this.state.publicClient.readContract({
        abi: TOKEN_ABI,
        account: this.state.account,
        address: addresses.PaymentToken,
        functionName: "allowance",
        args: [this.state.account, selectedIP.ipHolder],
      });
      if (approved == 0) {
        const hash = await this.state.walletClient.writeContract({
          abi: TOKEN_ABI,
          account: this.state.account,
          address: addresses.PaymentToken,
          functionName: "approve",
          args: [
            selectedIP.ipHolder,
            new BigNumber(Number.MAX_SAFE_INTEGER + 1)
              .multipliedBy(
                new BigNumber(10 ** this.state.paymentTokenDetails.decimals)
              )
              .toFixed(0),
          ],
        });
        await this.state.publicClient.waitForTransactionReceipt({
          hash: hash,
        });
        this.dispatch("success", "Successfully approved payment token");
        this.state.isLoading = false;
      }
      return approved == 0;
    },
    async purchaseLicense(_context, data) {
      if (!this.state.connected) return;
      try {
        const selectedIP = data.ip;
        await this.dispatch("checkPaymentTokenApproval", { ip: selectedIP });
        this.state.isLoading = true;
        const hash = await this.state.walletClient.writeContract({
          abi: IP_HOLDER_ABI,
          account: this.state.account,
          address: selectedIP.ipHolder,
          args: [
            {
              policyId: selectedIP.policyId,
              licensorIpId: selectedIP.ipIdAccount,
              amount: 1,
              receiver: this.state.account,
              royaltyContext:
                "0x3078300000000000000000000000000000000000000000000000000000000000",
            },
          ],
          functionName: "issueLicense",
        });
        await this.state.publicClient.waitForTransactionReceipt({
          hash: hash,
        });
        this.dispatch("success", "Successfully Purchased IP License");
      } catch (error) {
        console.error("Unable to purchase license: ", error);
        this.dispatch("error", "Unable to purchase license");
        this.state.isLoading = false;
      }
    },
    async getPurchasedLicenses(_context, data) {
      if (!this.state.connected) return;

      try {
        this.state.purchasedLicenses = [];
        const ipAccounts = await this.state.publicClient.readContract({
          abi: IP_REGISTRAR_ABI,
          account: this.state.account,
          address: addresses.IPHolderRegistrar,
          functionName: "allInstances",
          args: [],
        });

        for (const ipAccount of ipAccounts) {
          console.log("ipAccount: ", ipAccount, this.state.account);
          const [ips, cost] = await Promise.all([
            this.state.publicClient.readContract({
              abi: IP_HOLDER_ABI,
              account: this.state.account,
              address: ipAccount,
              functionName: "boughtLicenses",
              args: [this.state.account],
            }),
            this.state.publicClient.readContract({
              abi: IP_HOLDER_ABI,
              account: this.state.account,
              address: ipAccount,
              functionName: "minLicenseCost",
              args: [],
            }),
          ]);
          for (const ip of ips) {
            const isPDF = await this.dispatch("checkFileTypeIsPDF", ip.url);
            ip.isPDF = isPDF;
            ip.cost = new BigNumber(cost)
              .dividedBy(10 ** this.state.paymentTokenDetails.decimals)
              .toFixed(0);
            ip.paymentTokenSymbol = this.state.paymentTokenDetails.symbol;
            this.state.purchasedLicenses.push(ip);
          }
        }
      } catch (error) {
        console.error("Unable to load IPs: ", error);
        this.state.isLoading = false;
        this.state.purchasedLicenses = [];
      }
    },
    async getAllIPs(_context, data) {
      if (!this.state.connected) return;

      try {
        this.state.allIPS = [];
        const ipAccounts = await this.state.publicClient.readContract({
          abi: IP_REGISTRAR_ABI,
          account: this.state.account,
          address: addresses.IPHolderRegistrar,
          functionName: "allInstances",
          args: [],
        });

        console.log("ipAccounts: ", ipAccounts.length);
        for (const ipAccount of ipAccounts) {
          const cost = await this.state.publicClient.readContract({
            abi: IP_HOLDER_ABI,
            account: this.state.account,
            address: ipAccount,
            functionName: "minLicenseCost",
            args: [],
          });
          for (const ip of ipAccounts) {
            const ipAccountMintedIPs =
              await this.state.publicClient.readContract({
                abi: IP_HOLDER_ABI,
                account: this.state.account,
                address: ip,
                functionName: "allMintedIPs",
                args: [],
              });

            for (const mintedIP of ipAccountMintedIPs) {
              console.log("IPaa: ", mintedIP);
              const isPDF = await this.dispatch(
                "checkFileTypeIsPDF",
                mintedIP.url
              );
              const updatedIP = {
                ...mintedIP,
                isPDF: isPDF,
                cost: new BigNumber(cost)
                  .dividedBy(10 ** this.state.paymentTokenDetails.decimals)
                  .toFixed(0),
                paymentTokenSymbol: this.state.paymentTokenDetails.symbol,
                ipHolder: ip,
              };

              this.state.allIPS.push(updatedIP);
            }
          }

          console.log("ipAccount: ", ipAccount, this.state.account);
        }
      } catch (error) {
        console.error("Unable to load IPs: ", error);
        this.state.isLoading = false;
        this.state.purchasedLicenses = [];
      }
    },
    async isApprovedForAll(_context, _data) {
      try {
        if (!this.state.connected) return;
        this.state.isLoading = true;
        const approved = await this.state.publicClient.readContract({
          abi: NFT_ABI,
          account: this.state.account,
          address: addresses.IPIssuer,
          functionName: "isApprovedForAll",
          args: [this.state.account, this.state.selectedIP.address],
        });
        console.log("approved: ", approved);
        if (!approved) {
          const hash = await this.state.walletClient.writeContract({
            abi: NFT_ABI,
            account: this.state.account,
            address: addresses.IPIssuer,
            functionName: "setApprovalForAll",
            args: [this.state.selectedIP.address, true],
          });
          await this.state.publicClient.waitForTransactionReceipt({
            hash: hash,
          });
        }
        this.state.isLoading = false;
      } catch (error) {
        console.log("check approved error: ", error);
      }
    },
    async checkFileTypeIsPDF(_context, url) {
      try {
        const response = await fetch(url, { method: "GET" });
        const contentType = response.headers.get("Content-Type");
        console.log("Content-Type:", contentType);
        if (contentType.startsWith("image/")) {
          return false;
        } else if (contentType === "application/pdf") {
          this.isPDF = true;
          this.isImage = false;
          return true;
        }
      } catch (error) {
        return false;
      }
    },
    async mintIP(_context, data) {
      if (!this.state.connected) return;
      try {
        const form = data.form;
        await this.dispatch("isApprovedForAll");
        this.state.isLoading = true;
        const tokenIdHash = await this.state.walletClient.writeContract({
          abi: NFT_ABI,
          account: this.state.account,
          address: addresses.IPIssuer,
          functionName: "mint",
          args: [this.state.account],
        });
        const transaction = await this.state.publicClient.getTransactionReceipt(
          {
            hash: tokenIdHash,
          }
        );
        const transferEvent = decodeEventLog({
          abi: NFT_ABI,
          strict: false,
          topics: transaction.logs["0"].topics,
        });
        const tokenId = transferEvent.args.tokenId;
        console.log("tokenId: ", tokenId);
        const hash = await this.state.walletClient.writeContract({
          abi: IP_HOLDER_ABI,
          account: this.state.account,
          address: this.state.selectedIP.address,
          args: [
            {
              url: form.metadata.external_link,
              ipName: form.ipName,
              policyId: 1,
              tokenId: tokenId,
              contentHash:
                "0x3078300000000000000000000000000000000000000000000000000000000000",
              policySettings: {
                transferable: true,
                royaltyPolicy: "0x0000000000000000000000000000000000000000", // Using a zero address string
                mintingFee: 0,
                mintingFeeToken: "0x0000000000000000000000000000000000000000", // Using a zero address string
                policy: {
                  attribution: true,
                  commercialUse: false,
                  commercialAttribution: false,
                  commercializerChecker:
                    "0x0000000000000000000000000000000000000000",
                  commercializerCheckerData:
                    "0x3078300000000000000000000000000000000000000000000000000000000000",
                  commercialRevShare: 0,
                  derivativesAllowed: true,
                  derivativesAttribution: true,
                  derivativesApproval: false,
                  derivativesReciprocal: false,
                  territories: [],
                  distributionChannels: [],
                  contentRestrictions: [],
                },
              },
              attestationData: toHex(JSON.stringify(form.metadata)),
            },
          ],
          functionName: "registerAndAddPolicy",
        });
        await this.state.publicClient.waitForTransactionReceipt({
          hash: hash,
        });
        this.dispatch("successWithFooter", {
          message: "Successfully Minted IP",
          txHash: hash,
        });
        this.state.showIpDialog = false;
        this.state.isLoading = false;

        return true;
      } catch (error) {
        console.error("Unable to Mint IP: ", error);
        this.state.isLoading = false;
        this.dispatch("error", "Unable to Mint IP");
        return false;
      }
    },
    deployIP: async function (_context, data) {
      const form = data;
      console.log("form data: ", form);
      if (!this.state.connected) return;
      try {
        this.state.isLoading = true;
        //Deploy NFT Contract
        const hash = await this.state.walletClient.writeContract({
          abi: IP_REGISTRAR_ABI,
          account: this.state.account,
          address: addresses.IPHolderRegistrar,
          args: [
            {
              ipAssetRegistry: addresses.IPA_REGISTRY_ADDR,
              resolver: addresses.IP_RESOLVER_ADDR,
              nftToken: addresses.IPIssuer,
              registrationModule: addresses.REGISTRATION_MODULE,
              policyRegistrar: addresses.PILPOLICY_FRAMEWORK_MANAGER,
              licensingModule: addresses.LICENSING_MODULE,
              spg: addresses.STORY_PROTOCOL_GATEWAY_ADDR,
              licenseCost: new BigNumber(1000)
                .multipliedBy(10 ** this.state.paymentTokenDetails.decimals)
                .toFixed(0), //@dev 10K of whatever token,
              licenseToken: addresses.PaymentToken,
              licensingAttestation: addresses.LicensingAttestation,
            },
          ],
          functionName: "deployIP",
        });
        await this.state.publicClient.waitForTransactionReceipt({
          hash: hash,
        });
        this.dispatch("successWithFooter", {
          message: "Successfully Deployed IP",
          txHash: hash,
        });
        await Promise.all([
          this.dispatch("getAllIPs"),
          this.dispatch("loadUserIPs"),
          this.dispatch("getPurchasedLicenses"),
        ]);
        this.state.isLoading = false;
      } catch (error) {
        console.error("Unable to deploy IP: ", error);
        this.state.isLoading = false;
        this.dispatch("error", "Unable to deploy IP");
      }
    },
    getPaymentTokenDetails: async function (_context, _data) {
      if (!this.state.connected) return;
      try {
        this.state.isLoading = true;
        let tokenDetails = await Promise.all([
          this.state.publicClient.readContract({
            abi: TOKEN_ABI,
            address: addresses.PaymentToken,
            functionName: "name",
          }),
          this.state.publicClient.readContract({
            abi: TOKEN_ABI,
            address: addresses.PaymentToken,
            functionName: "symbol",
          }),
          this.state.publicClient.readContract({
            abi: TOKEN_ABI,
            address: addresses.PaymentToken,
            functionName: "decimals",
          }),
        ]);
        this.state.paymentTokenDetails = {
          name: tokenDetails[0],
          symbol: tokenDetails[1],
          decimals: tokenDetails[2],
          address: addresses.PaymentToken,
        };
        this.state.isLoading = false;
        console.log("tokenDetails: ", this.state.paymentTokenDetails);
      } catch (error) {
        console.error("Unable to load Payment Token Details: ", error);
        this.state.isLoading = false;
        this.dispatch("error", "Unable to load Payment Token Details");
      }
    },
    uploadFile: async function (_context, data) {
      try {
        this.state.isLoading = true;
        console.log("data: ", data.file);
        const formData = new FormData();
        formData.append("file", data.file, data.file.name);

        const output = await axios.post(
          "https://node.lighthouse.storage/api/v0/add",
          formData,
          {
            headers: {
              Authorization: `Bearer ${process.env.VUE_APP_LIGHTHOUSE_API_KEY}`,
            },
          }
        );

        console.log(
          "Visit at https://gateway.lighthouse.storage/ipfs/" + output.data.Hash
        );
        this.state.isLoading = false;
        this.dispatch("success", "Successfully uploaded file IP");
        return {
          success: true,
          uri: "https://gateway.lighthouse.storage/ipfs/" + output.data.Hash,
        };
      } catch (error) {
        console.error(
          "error uploading file",
          error,
          process.env.VUE_APP_LIGHTHOUSE_API_KEY
        );
        this.dispatch("error", "Error uploading file");
        this.state.isLoading = false;
      }
      return {
        success: false,
        uri: "",
      };
    },
    getMintedIPs: async function (_context, _data) {
      if (!this.state.connected) return;
      try {
        console.log("this.state.selectedIP: ", this.state.account);
        this.state.issuedIPs = [];
        this.state.isLoading = true;
        const [ips, cost] = await Promise.all([
          this.state.publicClient.readContract({
            abi: IP_HOLDER_ABI,
            address: this.state.selectedIP.address,
            args: [this.state.account],
            functionName: "accountIPDetails",
          }),
          this.state.publicClient.readContract({
            abi: IP_HOLDER_ABI,
            account: this.state.account,
            address: this.state.selectedIP.address,
            functionName: "minLicenseCost",
            args: [],
          }),
        ]);
        this.state.isLoading = false;
        console.log("mintedLicenses: ", ips);
        for (const ip of ips) {
          try {
            const [balance, isPDF] = await Promise.all([
              this.state.publicClient.readContract({
                abi: TOKEN_ABI,
                account: this.state.account,
                address: addresses.PaymentToken,
                functionName: "balanceOf",
                args: [ip.ipIdAccount],
              }),
              this.dispatch("checkFileTypeIsPDF", ip.url),
            ]);
            const updatedIP = {
              ...ip,
              isPDF: isPDF,
              cost: new BigNumber(cost)
                .dividedBy(10 ** this.state.paymentTokenDetails.decimals)
                .toFixed(0),
              paymentTokenSymbol: this.state.paymentTokenDetails.symbol,
              sales: new BigNumber(balance)
                .dividedBy(10 ** this.state.paymentTokenDetails.decimals)
                .toFixed(0),
            };
            this.state.issuedIPs.push(updatedIP);
          } catch (error) {
            console.error("Error processing IP:", ip, error);
          }
        }

        return ips;
      } catch (error) {
        console.error("Unable to load Issued Licenses: ", error);
        this.state.isLoading = false;
        this.dispatch("error", "Unable to load Issued Licenses");
        return [];
      }
    },
    loadUserIPs: async function (_context, _data) {
      if (!this.state.connected) return;
      try {
        this.state.isLoading = true;
        this.state.ips = [];
        const ips = await Promise.all([
          this.state.publicClient.readContract({
            abi: IP_REGISTRAR_ABI,
            account: this.state.account,
            address: addresses.IPHolderRegistrar,
            args: [this.state.account],
            functionName: "userIps",
          }),
        ]);
        console.log("valid: ", ips.length > 0, ips[0].length > 0);
        for (const ip of ips) {
          const ipAccounts = [];
          for (const ipAccount of ip) {
            try {
              const balance = await this.state.publicClient.readContract({
                abi: TOKEN_ABI,
                account: this.state.account,
                address: addresses.PaymentToken,
                functionName: "balanceOf",
                args: [ipAccount],
              });

              const tempAccount = {
                address: ipAccount,
                paymentTokenSymbol: this.state.paymentTokenDetails.symbol,
                balance: new BigNumber(balance)
                  .dividedBy(10 ** this.state.paymentTokenDetails.decimals)
                  .toFixed(0),
              };
              this.state.ips.push(tempAccount);
            } catch (error) {
              console.error(
                "Failed to fetch balance for account",
                ipAccount,
                error
              );
            }
          }
          console.log("Processed ipAccounts: ", ipAccounts);
        }
        console.log("ips: ", this.state.ips);
        this.state.isLoading = false;
      } catch (error) {
        console.error("Unable to load User IPs: ", error);
        this.state.isLoading = false;
        this.dispatch("error", "Unable to load User IPs");
      }
    },
    connectWallet: async function (_context, _data) {
      try {
        if (this.state.connected) {
          this.state.connected = false;
          this.state.account = "";
          return;
        }
        const provider = await detectEthereumProvider();
        if (!provider) return;
        this.state.isLoading = true;
        await this.dispatch("initContracts");
        this.dispatch("setupListeners");
        this.state.publicClient = createPublicClient({
          batch: {
            multicall: true,
          },
          chain: localhost,
          transport: custom(window.ethereum),
        });

        this.state.walletClient = createWalletClient({
          chain: localhost,
          transport: custom(window.ethereum),
        });
        console.log(await this.state.walletClient.getAddresses());
        const [accountsGet, accountsRequest] = await Promise.all([
          this.state.walletClient.getAddresses(),
          this.state.walletClient.requestAddresses(),
        ]);
        const accounts = accountsGet.length > 0 ? accountsGet : accountsRequest;
        if (accounts.length === 0) {
          this.state.isLoading = false;
          return;
        }
        this.state.account = accounts[0];
        this.state.connected = true;
        console.log("accounts: ", this.state.account);
        await Promise.all([
          this.dispatch("getPaymentTokenDetails"),
          this.dispatch("getPurchasedLicenses"),
        ]);
        await this.dispatch("loadUserIPs");
        this.state.isLoading = false;
      } catch (error) {
        console.error(error);
        this.state.isLoading = false;
      }
    },

    success(_context, message) {
      swal.fire({
        position: "top-end",
        icon: "success",
        title: "Success",
        showConfirmButton: false,
        timer: 2500,
        text: message,
      });
    },
    async switchToSepolia() {
      try {
        await ethereum.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: process.env.VUE_APP_CHAINID }],
        });
      } catch (switchError) {
        if (switchError.code === 4902) {
          // You can make a request to add the chain to wallet here
          console.log("Sepolia Testnet hasnt been added to the wallet!");
          await this.dispatch("addNetwork");
        }
      }
    },
    setupListeners: async function (_context, _data) {
      const chainId = await window.ethereum.request({ method: "eth_chainId" });
      console.log("chainId: ", chainId);
      if (chainId != process.env.VUE_APP_CHAINID) {
        await this.dispatch("switchToSepolia");
      }
      window.ethereum.on("chainChanged", async (_chainId) => {
        window.location.reload();
      });
      window.ethereum.on("accountsChanged", async (accounts) => {
        console.log("accounts: ", accounts);
        window.location.reload();
      });
    },
    async addNetwork() {
      try {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [
            {
              chainId: "0x89",
              rpcUrls: [process.env.VUE_RPC_URL],
              chainName: process.env.VUE_RPC_NAME,
              nativeCurrency: {
                name: process.env.VUE_RPC_CURRENCY,
                symbol: process.env.VUE_RPC_SYMBOL,
                decimals: process.env.VUE_RPC_DECIMALS,
              },
              blockExplorerUrls: ["https://polygonscan.com/"],
            },
          ],
        });
      } catch (error) {
        console.error("error adding chain", error);
      }
    },
    successWithCallBack(_context, message) {
      swal
        .fire({
          position: "top-end",
          icon: "success",
          title: "Success",
          showConfirmButton: true,
          text: message.message,
        })
        .then((results) => {
          if (results.isConfirmed) {
            message.onTap();
          }
        });
    },
    warning(_context, message) {
      swal.fire("Warning", message.warning, "warning").then((result) => {
        /* Read more about isConfirmed, isDenied below */
        if (result.isConfirmed) {
          message.onTap();
        }
      });
    },
    toastError(_context, message) {
      toast.error(message);
    },
    toastWarning(_context, message) {
      toast.warning(message);
    },
    toastSuccess(_context, message) {
      toast.success(message);
    },
    error(_context, message) {
      swal.fire({
        position: "top-end",
        icon: "error",
        title: "Error!",
        showConfirmButton: false,
        timer: 2500,
        text: message,
      });
    },
    successWithFooter(_context, message) {
      swal.fire({
        position: "top-end",
        icon: "success",
        title: "Success",
        text: message.message,
        footer: `<a href=https://sepolia.etherscan.io//txs/${message.txHash}> View on Sepolia scan</a>`,
      });
    },
    errorWithFooterMetamask(_context, message) {
      swal.fire({
        icon: "error",
        title: "Error!",
        text: message,
        footer: `<a href= https://metamask.io> Download Metamask</a>`,
      });
    },
  },
  modules: {},
});
