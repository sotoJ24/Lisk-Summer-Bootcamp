const hre = require("hardhat");

async function main() {
  console.log("Deploying UserProfile contract...");

  const UserProfile = await hre.ethers.getContractFactory("UserProfile");
  const userProfile = await UserProfile.deploy();

  await userProfile.waitForDeployment();

  console.log("UserProfile deployed to:", await userProfile.getAddress());
  
  const [owner] = await hre.ethers.getSigners();
  console.log("Testing with account:", owner.address);
  
  try {
    await userProfile.register("Test User", 25, "test@example.com");
    console.log("✅ Test registration successful!");
    
    const profile = await userProfile.getProfile();
    console.log("Profile:", {
      name: profile.name,
      age: profile.age.toString(),
      email: profile.email
    });
  } catch (error) {
    console.log("❌ Test failed:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });