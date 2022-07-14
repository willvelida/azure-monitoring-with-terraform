using Newtonsoft.Json;
using System;

namespace TransactionGenerator.Models
{
    public class Transaction
    {
        [JsonProperty(PropertyName = "id")]
        public string Id { get; set; }
        public string TransactionId { get; set; }
        public string ProductName { get; set; }
        public decimal PurchaseAmount { get; set; }
        public DateTime PurchaseDate { get; set; }
    }
}
