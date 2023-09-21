// Developed by gevivesh
// This Code is an educational example take as is no warranty
// Microsoft is not responsible for this no warranty

async function UpdateDisk(subscriptionId, ResourceGroup, diskName,sku,tier) {
  const computeClient = new ComputeManagementClient(
    credentials,
    subscriptionId
  );

  const operation_result = await computeClient.disks.beginUpdateAndWait(
    ResourceGroup,
    diskName,
    {
      sku: {
        name: sku, 
        tier: TIER,
      },
    }
  );

  console.log(operation_result);
}

// CODE STARTING POINT
console.log("STARTING POINT");
const {
  ClientSecretCredential,
  DefaultAzureCredential,
  InteractiveBrowserCredential,
} = require("@azure/identity");
const { ComputeManagementClient } = require("@azure/arm-compute");

// Azure authentication in environment variables for DefaultAzureCredential
let credentials = null;
const subscriptionId = "xxxxx-xxxx-xxxxx-xxxx-xxx";
const ResourceGroup = "ResourceGroupName";
const DiskName = "DiskName";

const SKU = "StandardSSD_LRS"; // VALUES ARE COMMONLY KNOW AS PREMIUM ,SSD , HDD  on backend are  https://learn.microsoft.com/en-us/rest/api/compute/disks/list?tabs=HTTP#disksku
const TIER = "E15";  // CHECK VALUES ON https://azure.microsoft.com/en-us/pricing/details/managed-disks/  values like as example P10 , E10 , S10 


// development credentials you can get this in different ways 
//  ref https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential?view=azure-dotnet
credentials = new InteractiveBrowserCredential();
// LET'S UPDATE THE DISK TIER 
UpdateDisk(subscriptionId, ResourceGroup, DiskName,SKU,TIER);