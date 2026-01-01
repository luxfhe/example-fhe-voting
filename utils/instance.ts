import { fhe } from "@luxfhe/sdk/node";
import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

import { waitForBlock } from "./block";

export interface FheContract {
  initialized: boolean;
}

export async function createFheInstance(hre: HardhatRuntimeEnvironment, contractAddress: string): Promise<FheContract> {
  const { ethers } = hre;

  // workaround for call not working the first time on a fresh chain
  try {
    await ethers.provider.getBlockNumber();
  } catch (_) {
    await waitForBlock(hre);
  }

  // Initialize the FHE SDK
  await fhe.initialize();

  return { initialized: true };
}
