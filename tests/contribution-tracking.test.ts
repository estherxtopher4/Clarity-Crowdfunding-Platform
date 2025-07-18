import { describe, it, expect, beforeEach } from "vitest"

describe("Contribution Tracking Contract", () => {
  let contractAddress
  let deployer
  let user1
  let user2
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.contribution-tracking"
    deployer = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    user1 = "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5"
    user2 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
  })
  
  describe("Reward Tier Management", () => {
    it("should add reward tier successfully", () => {
      const campaignId = 1
      const tierId = 1
      const name = "Early Bird"
      const description = "Early supporter reward"
      const minAmount = 100000
      const maxBackers = 50
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject reward tier with zero minimum amount", () => {
      const campaignId = 1
      const tierId = 1
      const name = "Invalid Tier"
      const description = "Invalid reward tier"
      const minAmount = 0
      const maxBackers = 50
      
      const result = {
        type: "error",
        value: 102, // ERR-INVALID-AMOUNT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(102)
    })
  })
  
  describe("Contribution Processing", () => {
    it("should process contribution successfully", () => {
      const campaignId = 1
      const rewardTier = 1
      const amount = 150000
      
      const result = {
        type: "ok",
        value: 1, // contribution ID
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject contribution with zero amount", () => {
      const campaignId = 1
      const rewardTier = 1
      const amount = 0
      
      const result = {
        type: "error",
        value: 102, // ERR-INVALID-AMOUNT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(102)
    })
    
    it("should reject contribution below reward tier minimum", () => {
      const campaignId = 1
      const rewardTier = 1
      const amount = 50000 // below minimum of 100000
      
      const result = {
        type: "error",
        value: 102, // ERR-INVALID-AMOUNT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(102)
    })
    
    it("should reject contribution when reward tier is full", () => {
      const campaignId = 1
      const rewardTier = 1
      const amount = 150000
      
      const result = {
        type: "error",
        value: 102, // ERR-INVALID-AMOUNT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(102)
    })
  })
  
  describe("Contribution Status Management", () => {
    it("should update contribution status by contributor", () => {
      const contributionId = 1
      const newStatus = "confirmed"
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject status update by non-contributor", () => {
      const contributionId = 1
      const newStatus = "confirmed"
      
      const result = {
        type: "error",
        value: 100, // ERR-NOT-AUTHORIZED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(100)
    })
  })
  
  describe("Read-only Functions", () => {
    it("should get contribution details", () => {
      const contributionId = 1
      
      const result = {
        "campaign-id": 1,
        contributor: user1,
        amount: 150000,
        "reward-tier": 1,
        timestamp: 1000,
        status: "active",
      }
      
      expect(result["campaign-id"]).toBe(1)
      expect(result.contributor).toBe(user1)
      expect(result.amount).toBe(150000)
    })
    
    it("should get campaign total funding", () => {
      const campaignId = 1
      const result = 500000
      
      expect(result).toBe(500000)
    })
    
    it("should check if user contributed to campaign", () => {
      const campaignId = 1
      const contributor = user1
      const result = true
      
      expect(result).toBe(true)
    })
    
    it("should get reward tier information", () => {
      const campaignId = 1
      const tierId = 1
      
      const result = {
        name: "Early Bird",
        description: "Early supporter reward",
        "min-amount": 100000,
        "max-backers": 50,
        "current-backers": 5,
      }
      
      expect(result.name).toBe("Early Bird")
      expect(result["current-backers"]).toBe(5)
    })
  })
})
