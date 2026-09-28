package com.omnicart.mapper;

import com.omnicart.dto.response.SellerResponse;
import com.omnicart.entity.Seller;

public class SellerMapper {
    public static SellerResponse toResponse(Seller seller) {
        if (seller == null) return null;
        SellerResponse res = new SellerResponse();
        res.setId(seller.getId());
        res.setCompanyName(seller.getCompanyName());
        res.setGstin(seller.getGstin());
        res.setContactEmail(seller.getContactEmail());
        res.setContactPhone(seller.getContactPhone());
        res.setCreatedAt(seller.getCreatedAt());
        return res;
    }
}
