//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace sfShareLib
{
    using System;
    using System.Collections.Generic;
    
    public partial class IoTDeviceMessageCatalog
    {
        public int Id { get; set; }
        public string IoTHubDeviceID { get; set; }
        public int MessageCatalogID { get; set; }
        public System.DateTime CreatedAt { get; set; }
        public Nullable<System.DateTime> UpdatedAt { get; set; }
        public bool DeletedFlag { get; set; }
    
        public virtual IoTDevice IoTDevice { get; set; }
        public virtual MessageCatalog MessageCatalog { get; set; }
    }
}
