package com.omnicart.dto.request;

import jakarta.validation.constraints.NotNull;

public class ShippingStatusUpdateRequest {
    @NotNull(message = "Status ID is required (1: Pending, 2: Processing, 3: Shipped, 4: In Transit, 5: Delivered, 6: Cancelled, 7: Returned)")
    private Integer statusId;

    public ShippingStatusUpdateRequest() {}

    public Integer getStatusId() { return statusId; }
    public void setStatusId(Integer statusId) { this.statusId = statusId; }
}
