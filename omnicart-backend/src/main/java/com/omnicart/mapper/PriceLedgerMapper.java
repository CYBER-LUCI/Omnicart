package com.omnicart.mapper;

import com.omnicart.dto.response.PriceLedgerResponse;
import com.omnicart.entity.PriceLedger;

public class PriceLedgerMapper {
    public static PriceLedgerResponse toResponse(PriceLedger ledger) {
        if (ledger == null) return null;
        PriceLedgerResponse res = new PriceLedgerResponse();
        res.setId(ledger.getId());
        res.setProductId(ledger.getProduct() != null ? ledger.getProduct().getId() : null);
        res.setSourceName(ledger.getSource() != null ? ledger.getSource().getSourceName() : null);
        res.setPrice(ledger.getPrice());
        res.setPriceFluctuation(ledger.getPriceFluctuation());
        res.setRecordedAt(ledger.getRecordedAt());
        return res;
    }
}
