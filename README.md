To test this smart contract, on an Ethereum environment like remix.ethereum.org.

Register the recipients before the donors by using the hospitalReqReg and hospitalDonaReg functions respectively. 

Use the number returned after the donor's registration and the organ name to execute the matching function by using the matchingListDonor funtion.

The matching function will return a matching ID number.

Using the matching ID number the bestMatch function will reveal the donor ID number and the highest priority recipient ID number.

The donor and the recipient are expected to accept the match result by using donorAccept and recipientAccept respectively, after the cross-matching and any possible consern has been addressed.

The blockchain system track any changes in the system activity.
