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
    
    public partial class AlarmRuleItem
    {
        public int Id { get; set; }
        public int AlarmRuleCatalogId { get; set; }
        public int Ordering { get; set; }
        public Nullable<int> MessageElementParentId { get; set; }
        public int MessageElementId { get; set; }
        public string EqualOperation { get; set; }
        public string Value { get; set; }
        public string BitWiseOperation { get; set; }
    
        public virtual AlarmRuleCatalog AlarmRuleCatalog { get; set; }
        public virtual MessageElement MessageElement { get; set; }
        public virtual MessageElement MessageElement1 { get; set; }
    }
}
