using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NotificationRetryRequest
    {
        public List<Guid>? NotificationIds { get; set; }
    }
}
