package com.omnicart.mapper;

import com.omnicart.dto.response.OrderDetailResponse;
import com.omnicart.dto.response.OrderPaymentResponse;
import com.omnicart.dto.response.OrderResponse;
import com.omnicart.entity.Order;
import com.omnicart.entity.OrderDetails;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class OrderMapper {
    public static OrderResponse toResponse(Order order) {
        if (order == null) return null;
        OrderResponse res = new OrderResponse();
        res.setId(order.getId());
        if (order.getCustomer() != null) {
            res.setCustomerId(order.getCustomer().getId());
            res.setCustomerName(order.getCustomer().getFirstName() + " " + order.getCustomer().getLastName());
        }
        res.setShippingStatus(order.getShippingStatus() != null ? order.getShippingStatus().getStatusName() : null);
        res.setOrderDate(order.getOrderDate());

        BigDecimal total = BigDecimal.ZERO;
        List<OrderDetailResponse> itemResponses = new ArrayList<>();
        if (order.getOrderDetails() != null) {
            for (OrderDetails od : order.getOrderDetails()) {
                OrderDetailResponse odRes = new OrderDetailResponse();
                if (od.getProduct() != null) {
                    odRes.setProductId(od.getProduct().getId());
                    odRes.setProductName(od.getProduct().getName());
                }
                odRes.setQuantity(od.getQuantity());
                odRes.setExactLedgerPrice(od.getExactLedgerPrice());
                odRes.setLedgerId(od.getLedger() != null ? od.getLedger().getId() : null);
                odRes.setLineTotal(od.getLineTotal());
                total = total.add(od.getLineTotal());
                itemResponses.add(odRes);
            }
        }
        res.setItems(itemResponses);
        res.setTotalAmount(total);

        if (order.getPayment() != null) {
            OrderPaymentResponse payRes = new OrderPaymentResponse();
            payRes.setId(order.getPayment().getId());
            payRes.setPaymentMethod(order.getPayment().getPaymentMethod() != null ? order.getPayment().getPaymentMethod().getMethodName() : null);
            payRes.setPaidAmount(order.getPayment().getPaidAmount());
            payRes.setPaidAt(order.getPayment().getPaidAt());
            res.setPayment(payRes);
        }
        return res;
    }
}
