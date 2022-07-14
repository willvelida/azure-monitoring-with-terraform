using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
