module Positioning
  # rekimoto method
  class WeightedAverage
    include WifiParams

    class << self
      def estimate_by_map(options = {})
        movement_log = options[:movement_log]
        x = 0
        y = 0
        z = 0
        dist_sum = 0.0
        movement_log.wifi_logs.each do |wifi_log|
          # skip unlocated wifi_access_point
          next if wifi_log.wifi_access_point.manual_location.nil?
          x += wifi_log.wifi_access_point.manual_location.x / self.dist_value(wifi_log.signal)
          y += wifi_log.wifi_access_point.manual_location.y / self.dist_value(wifi_log.signal)
          z += (wifi_log.wifi_access_point.manual_location.height + wifi_log.wifi_access_point.manual_location.map.o_alt) / self.dist_value(wifi_log.signal)
          dist_sum += 1 / self.dist_value(wifi_log.signal)
        end
        [(x / dist_sum), (y / dist_sum), (z / dist_sum) - movement_log.manual_location.map.o_alt]
      end

      def estimate_by_geom(options = {})
        movement_log = options[:movement_log]
        avg_geom = Point.from_lon_lat_z(0.0, 0.0, 0.0, Coordinate::SRID)
        dist_sum = 0.0
        movement_log.wifi_logs.each do |wifi_log|
          # skip unlocated wifi_access_point
          next if wifi_log.wifi_access_point.manual_location.nil?
          avg_geom.x += wifi_log.wifi_access_point.manual_location.geom.lon / self.dist_value(wifi_log.signal)
          avg_geom.y += wifi_log.wifi_access_point.manual_location.geom.lat / self.dist_value(wifi_log.signal)
          avg_geom.z += wifi_log.wifi_access_point.manual_location.geom.z / self.dist_value(wifi_log.signal)
          dist_sum += 1 / self.dist_value(wifi_log.signal)
        end
        avg_geom = Point.from_lon_lat_z(avg_geom.lon / dist_sum, avg_geom.lat / dist_sum, avg_geom.z / dist_sum, Coordinate::SRID)
      end

      def estimate_by_sql(options = {})
        target = options[:movement_log]
        geom = "manual_locations.geom"
        dist = self.dist
        calc = "sum((x(#{geom})) / #{dist}) / sum(1 / #{dist}), sum((y(#{geom})) / #{dist}) / sum(1 / #{dist}), sum((z(#{geom})) / #{dist}) / sum(1 / #{dist})"
        Point.from_hex_ewkb(MovementLog.calculate(:st_makepoint, calc, {:include => {:wifi_logs => {:wifi_access_points => :manual_locations}}, :conditions => ['movement_logs.id = ? and .geom IS NOT NULL', target.id]}))
      end
    end
  end
end

